#!/usr/bin/env bash
# Shared, backend-agnostic helpers sourced by every wizard stage. Not
# directly executable. The actual wiz_msgbox/wiz_yesno/wiz_input/
# wiz_password/wiz_menu/wiz_checklist/wiz_textbox/wiz_textarea/wiz_notice
# UI primitives live in lib/ui-tui.sh (whiptail) or lib/ui-web.sh
# (browser-driven) — run.sh sources exactly one of those, selected via
# WIZ_UI_BACKEND, after this file. Everything here works identically
# regardless of which backend is active.

declare -gA WIZ=()

wiz_set() { WIZ["$1"]="$2"; }
wiz_get() { printf '%s' "${WIZ[$1]:-}"; }
wiz_unset() { unset "WIZ[$1]"; }

# shellcheck disable=SC2034  # used by lib/ui-tui.sh and lib/wiz-claim.sh
WHIPTAIL_BACKTITLE="TerraMaster-family NAS installer"

# The baked-in repo copy lives here (see hosts/installer/configuration.nix
# — environment.etc."nas-installer-repo" points at the flake's own `self`).
# Copied to WIZ_REPO_WORKDIR (writable) before the wizard generates
# anything into it, optionally refreshed from WIZ_REPO_URL first.
: "${WIZ_REPO_BAKED_IN:=/etc/nas-installer-repo}"
: "${WIZ_REPO_WORKDIR:=/root/terramaster-nix}"
: "${WIZ_REPO_URL:=https://github.com/BeardedTek/terramaster-nix.git}"

# Shared by lib/wiz-claim.sh, lib/ui-web.sh, and wiz_progress below —
# tmpfs, fresh every boot (see hosts/installer/configuration.nix's
# systemd.tmpfiles.rules for this path).
: "${WIZ_RUN_DIR:=/run/wiz-web}"

wiz_abort() {
  echo "Installer wizard aborted: ${1:-cancelled by user}" >&2
  clear
  exit 1
}

wiz_die() {
  wiz_msgbox "Error" "$1"
  wiz_abort "$1"
}

# /etc/hostid is a NixOS-managed symlink into the read-only Nix store on
# this live ISO (hosts/installer/configuration.nix sets networking.hostId
# = "00000000", which makes NixOS manage /etc/hostid the same way it
# manages every other environment.etc entry) — confirmed the hard way
# that `zgenhostid -f` fails against it directly ("Read-only file
# system") even running as root, since that's a property of the
# underlying Nix store mount, not a permission-bits issue. Removing the
# symlink first lets zgenhostid write a real, regular file in its place.
# Every caller that needs the live session's hostid to match a target
# system's configured hostid (both storage paths, at different points)
# should go through this rather than calling zgenhostid directly.
wiz_set_hostid() {
  local host_id="$1"
  rm -f /etc/hostid
  zgenhostid -f "$host_id"
}

# Requires the user to type $2 verbatim to continue. Used for destructive
# confirmations — a yes/no dialog is too easy to reflexively click through.
wiz_type_to_confirm() {
  local prompt="$1" required="$2" typed
  typed=$(wiz_input "Confirm" "$prompt

Type $required (all caps, exactly) to continue.")
  [ "$typed" = "$required" ]
}

# Backend-agnostic install-progress checkpoint, called only from
# stages/90-install.sh (the one stage with a long unattended stretch that
# isn't made of wiz_* calls at all — disko, secret generation,
# nixos-install itself). A silent no-op unless something has actually
# created $WIZ_RUN_DIR (the web backend's systemd service does; Tier 1's
# mocked environment and a plain TUI-only boot never do, and shouldn't
# need to for this to work).
wiz_progress() {  # $1=step key  $2=running|done|failed  $3=optional message
  [ -d "$WIZ_RUN_DIR" ] || return 0
  jq -nc --arg step "$1" --arg state "$2" --arg msg "${3:-}" --arg time "$(date -Is)" \
    '{step:$step, state:$state, message:$msg, time:$time}' \
    >> "$WIZ_RUN_DIR/install-progress.jsonl" 2>/dev/null || true
}

# Shared by both wiz_notice backends (lib/ui-tui.sh, lib/ui-web.sh) —
# appends the notice into the same install.log the WebUI's log panel
# tails, so a run driven over the web still shows a real, readable
# timeline ("== Running disko ==" etc.) during the stretch before
# nixos-install's own output starts flowing into that same file.
_wiz_notice_log() {
  [ -d "$WIZ_RUN_DIR" ] || return 0
  {
    echo
    echo "== $1 =="
    [ -n "${2:-}" ] && echo "$2"
  } >> "$WIZ_RUN_DIR/install.log" 2>/dev/null || true
}
