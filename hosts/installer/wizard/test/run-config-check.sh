#!/usr/bin/env bash
# Tier 1: drives the real wizard stage functions (00 through 80) with
# whiptail mocked out, then evaluates the resulting variables.nix/
# configuration.nix/disko.nix the same way `nix flake check`/`nixos-install`
# would — catching missing-option/eval bugs (e.g. mySystem.domain having
# no default and never being set) in seconds, no VM needed. Does NOT run
# stage_90_install — that has real disko/nixos-install/reboot side effects,
# covered instead by run-vm-install.sh (Tier 2).
#
# Run from this repo (any checkout) via WSL, since the stages call real
# Linux tools (ip, blkid) that don't exist in a plain Windows shell:
#   wsl -d NixOS -- bash hosts/installer/wizard/test/run-config-check.sh
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIZARD_DIR="$(dirname "$TEST_DIR")"
REPO_ROOT="$(cd "$WIZARD_DIR/../../.." && pwd)"

# Only WORKDIR needs to be fresh per run (stage_10_repo_update rm -rf's
# and repopulates it every time anyway). BAKED_IN — the stand-in for the
# ISO's baked-in repo snapshot, hosts/installer/configuration.nix's
# environment.etc."nas-installer-repo" — is a STABLE cache path instead
# of a fresh mktemp dir, specifically so rsync has something to diff
# against on the 2nd+ run. $REPO_ROOT lives on a Windows-mounted drvfs
# path when run under WSL (the normal way to invoke this) — crossing that
# boundary is the slow part, by far, not the copy tool itself; a full
# `rsync` of the repo took ~10 minutes the first time. An unconditional
# fresh-tmpdir copy on every run was paying that full cost every single
# time for no reason — this cuts every run after the first down to
# whatever actually changed since the last one.
CACHE_DIR="${WIZ_TEST_CACHE_DIR:-${TMPDIR:-/tmp}/wiz-test-cache}"
export WIZ_REPO_BAKED_IN="$CACHE_DIR/baked-in"
mkdir -p "$WIZ_REPO_BAKED_IN"

SCRATCH="$(mktemp -d)"
# run-vm-install.sh (Tier 2) reuses this script to generate a known-good
# config, then copies it into a live VM — set WIZ_TEST_KEEP_SCRATCH=1 to
# skip cleanup so the caller can read $WIZ_REPO_WORKDIR back out.
if [ "${WIZ_TEST_KEEP_SCRATCH:-0}" != "1" ]; then
  trap 'rm -rf "$SCRATCH"' EXIT
fi
export WIZ_REPO_WORKDIR="$SCRATCH/workdir"

# docs/ is a wholly separate Hugo site — no NixOS module ever references
# it, unlike dashboard/ (modules/dashboard.nix's `src = ../dashboard;`
# build input, has to stay). Excluding it outright, not just its
# build-output subdirs, is most of the remaining size after .git.
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete --exclude='.git/' --exclude='docs/' "$REPO_ROOT/" "$WIZ_REPO_BAKED_IN/"
else
  rm -rf "$WIZ_REPO_BAKED_IN"
  cp -r "$REPO_ROOT" "$WIZ_REPO_BAKED_IN"
  rm -rf "$WIZ_REPO_BAKED_IN/.git" "$WIZ_REPO_BAKED_IN/docs"
fi

source "$WIZARD_DIR/lib/common.sh"
source "$TEST_DIR/lib/mock-wiz.sh"
source "$WIZARD_DIR/lib/pool-existing.sh"
source "$WIZARD_DIR/lib/pool-new.sh"
source "$WIZARD_DIR/lib/generate-config.sh"
for stage in "$WIZARD_DIR"/stages/*.sh; do
  # shellcheck disable=SC1090
  source "$stage"
done

FIXTURE="${1:-$TEST_DIR/fixtures/answers-new-pool.sh}"
echo "== Tier 1 config check: fixture $(basename "$FIXTURE") ==" >&2
# shellcheck disable=SC1090
source "$FIXTURE"
mock_wiz_init_queues

stage_00_welcome
stage_10_repo_update
stage_20_network
stage_30_instance
stage_40_storage
stage_50_users
stage_60_features
stage_70_secrets
stage_80_review

manufacturer=$(wiz_get manufacturer)
instance=$(wiz_get instance)
hostname=$(wiz_get hostname)
host_dir="$WIZ_REPO_WORKDIR/hosts/$manufacturer/$instance"

gen_variables_nix > "$WIZ_REPO_WORKDIR/variables.nix"
if [ "$(wiz_get storage_path)" = "existing" ]; then
  gen_configuration_nix_existing > "$host_dir/configuration.nix"
else
  gen_configuration_nix_new > "$host_dir/configuration.nix"
fi

# modules/users.nix's assertions just need these non-empty — the actual
# hash value is never checked against anything in an eval-only test, so
# a fixed dummy sha-512 crypt string (real shape, doesn't need mkpasswd
# present in this environment) is fine.
DUMMY_HASH='$6$dummySaltForTest$Yl3Z8O1nQ2xqzq9k3q9k3q9k3q9k3q9k3q9k3q9k3q9k3q9k3q9k3q9k3q9k3q9k3q9k3q9k3q9k3q9k3q9k'
export ROOT_INITIAL_HASH="$DUMMY_HASH"
local_name=
while IFS= read -r local_name; do
  [ -z "$local_name" ] && continue
  export "$(echo "$local_name" | tr '[:lower:]' '[:upper:]')_INITIAL_HASH=$DUMMY_HASH"
done <<< "$(wiz_get user_list)"

# Also written to disk (unlike a real run, which only sets these in the
# environment via 90-install.sh's own gen_initial_passwords_env + source)
# so run-vm-install.sh (Tier 2) can copy this scratch checkout onto the
# live VM and `source` it there exactly like a real install would.
gen_initial_passwords_env > "$WIZ_REPO_WORKDIR/secrets/initial-passwords.env" 2>/dev/null || {
  mkdir -p "$WIZ_REPO_WORKDIR/secrets"
  { echo "ROOT_INITIAL_HASH='$DUMMY_HASH'"; \
    while IFS= read -r local_name; do \
      [ -z "$local_name" ] && continue; \
      echo "$(echo "$local_name" | tr '[:lower:]' '[:upper:]')_INITIAL_HASH='$DUMMY_HASH'"; \
    done <<< "$(wiz_get user_list)"; \
  } > "$WIZ_REPO_WORKDIR/secrets/initial-passwords.env"
}

echo "== Generated files (in $WIZ_REPO_WORKDIR) ==" >&2
echo "-- variables.nix --" >&2
cat "$WIZ_REPO_WORKDIR/variables.nix" >&2
echo "-- $host_dir/configuration.nix --" >&2
cat "$host_dir/configuration.nix" >&2
echo "-- $host_dir/disko.nix --" >&2
cat "$host_dir/disko.nix" >&2

echo "== nix eval: nixosConfigurations.$hostname.config.system.build.toplevel ==" >&2
# --raw prints the drvPath with no trailing newline; only the exit status
# matters here, and that missing newline was gluing this onto the
# machine-parseable WIZ_REPO_WORKDIR= line below (same stdout stream) when
# a caller (Tier 2) greps for it — discard it instead of printing it.
if ! NIX_CONFIG="pure-eval = false" nix eval --impure --raw \
    "$WIZ_REPO_WORKDIR#nixosConfigurations.$hostname.config.system.build.toplevel.drvPath" >/dev/null; then
  echo >&2
  echo "TIER 1 FAILED: config generated by the wizard doesn't evaluate — see the trace above." >&2
  exit 1
fi

echo >&2
echo "TIER 1 PASSED: generated config evaluates cleanly." >&2
# Machine-parseable line for run-vm-install.sh (Tier 2) to pick up when
# WIZ_TEST_KEEP_SCRATCH=1 — the scratch checkout survives this script's
# exit specifically so the caller can copy it into a live VM.
echo "WIZ_REPO_WORKDIR=$WIZ_REPO_WORKDIR"
echo "WIZ_HOSTNAME=$hostname"
echo "WIZ_MANUFACTURER=$manufacturer"
echo "WIZ_INSTANCE=$instance"
