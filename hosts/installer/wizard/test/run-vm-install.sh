#!/usr/bin/env bash
# Tier 2: builds a throwaway ISO with a test SSH key baked in, creates a
# FRESH VirtualBox VM + fresh disks matching the new-pool path's topology
# (one boot disk, four pool disks), and drives the REAL, unmodified
# hosts/installer/wizard/run.sh interactively via VirtualBox's own
# keyboard-injection API (VBoxManage controlvm keyboardputstring /
# keyboardputscancode) — these land on the VM's actual virtual keyboard,
# read by whichever process has the console focused, exactly like a
# person typing at the VM's screen. Real whiptail dialogs, real
# keystrokes, real disko, real nixos-install. The VM and its disks are
# destroyed at the end regardless of pass/fail, so every run starts from
# the same known-clean state.
#
# This deliberately does NOT reuse the mocked wiz_* stand-ins from
# lib/mock-wiz.sh / run-config-check.sh (Tier 1) — those test the wizard's
# stage *logic* fast and cheaply, but never execute run.sh or whiptail
# itself, and stage_90_install's actual disko/secrets/nixos-install
# sequence would otherwise only ever run as a hand-duplicated copy in this
# script. Driving the real TUI here closes that gap: every bug this test
# finds is a bug a real user typing at a real console would also hit.
#
# An earlier version of this script drove run.sh over an interactive SSH
# pty instead (a hand-rolled `expect`), reading its output via a
# backgrounded `cat` on a bash `coproc` file descriptor. That hit a real
# Git-Bash-on-Windows bug — reading a coproc's fd from a *backgrounded*
# command fails with "Bad file descriptor" even though the identical
# foreground read works fine — and, independently of that bug, an SSH pty
# session is a *different* login than the VM's own console anyway
# (environment.loginShellInit below launches run.sh on both, but they're
# separate instances), so it wasn't actually exercising what a person at
# the console would see. Keyboard injection avoids both problems.
#
# Run from Git Bash on the Windows host (this tier is host-tooling —
# VBoxManage/VM lifecycle isn't part of the NixOS flake itself):
#   bash hosts/installer/wizard/test/run-vm-install.sh
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIZARD_DIR="$(dirname "$TEST_DIR")"
REPO_ROOT="$(cd "$WIZARD_DIR/../../.." && pwd)"

# Git Bash's own paths (this script's own location, under the repo
# checkout) are already /c/... — a plain prefix swap to /mnt/c/... is
# enough for those. mktemp-created scratch paths are NOT: Git Bash's
# mktemp creates them under /tmp/..., which is actually
# C:\Users\<user>\AppData\Local\Temp\... on disk (confirmed via
# `cygpath -w`), nothing to do with /c/ at all — a naive "${path#/c/}"
# prefix-strip is a silent no-op on those and produces a broken WSL path
# (hit this exact bug the first run: rsync tried to mkdir
# "/mnt/c//tmp/tmp.XXX/..."). cygpath -w gives the real Windows path
# for *any* input regardless of which of Git Bash's path styles it's
# in, so converting through that is reliable both ways.
to_wsl_path() {
  local winpath="$1"
  winpath="$(cygpath -w "$winpath")"
  local drive="${winpath:0:1}"
  drive="$(printf '%s' "$drive" | tr '[:upper:]' '[:lower:]')"
  # bash's own ${var//\\//} pattern-substitution syntax turned out not to
  # match a literal backslash here (confirmed in isolation — it silently
  # left every backslash untouched); tr is unambiguous for a plain
  # single-character swap, so just use that instead of fighting the
  # parameter-expansion escaping rules further.
  local rest
  rest="$(printf '%s' "${winpath:2}" | tr '\\' '/')"
  printf '/mnt/%s%s' "$drive" "$rest"
}

# Fresh VM + fresh disks every run, destroyed at the end regardless of
# pass/fail — repeatable (no state a previous run might have left behind
# to skew the next one) rather than reusing one fixed VM across runs.
VM_NAME="${WIZ_VM_NAME:-wiz-test-$(date +%Y%m%d-%H%M%S)-$$}"
VBM="/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
SSH_PORT="${WIZ_SSH_PORT:-2222}"
BOOT_TIMEOUT_SECS="${WIZ_BOOT_TIMEOUT_SECS:-300}"
# Matches the hand-built terramaster-nix-installer VM's own spec (checked
# via VBoxManage showvminfo/list hdds) — same topology the wizard's new-
# pool path is meant for: one small boot disk, four equal pool disks.
VM_OSTYPE="Linux26_64"
VM_MEMORY_MB=8192
VM_CPUS=2
BOOT_DISK_MB=4096
POOL_DISK_MB=10240

# Test identity — same values matched against these exact strings
# throughout the interaction script below.
TEST_MANUFACTURER="terramaster"
TEST_INSTANCE="wiztest"
TEST_DOMAIN="test.invalid"
TEST_ROOT_PW="TestRootPass123!"
TEST_ADMIN_PW="TestAdminPass123!"
TEST_USER2_PW="TestUser2Pass123!"
TEST_LDAP_PW="TestLdapAdmin123!"

SCRATCH="$(mktemp -d)"
VM_CREATED=0
# Set to keep the VM running (rebooted into the *installed* system, not
# powered off/destroyed) for post-install verification — e.g. checking
# that LLDAP/dashboard/services actually work, not just that
# nixos-install exited 0. Off by default: normal runs still clean up
# every time.
WIZ_TEST_KEEP_VM="${WIZ_TEST_KEEP_VM:-0}"
cleanup() {
  if [ "$WIZ_TEST_KEEP_VM" = "1" ] && [ "${WIZ_TEST_PASSED:-0}" = "1" ]; then
    echo "== WIZ_TEST_KEEP_VM=1: leaving $VM_NAME running (SSH port $SSH_PORT), not destroying. ==" >&2
    echo "Scratch dir (test key, etc.) preserved: $SCRATCH" >&2
    return 0
  fi
  echo "== Cleaning up: destroying $VM_NAME ==" >&2
  "$VBM" controlvm "$VM_NAME" poweroff >/dev/null 2>&1 || true
  sleep 2
  if [ "$VM_CREATED" = "1" ]; then
    "$VBM" unregistervm "$VM_NAME" --delete >/dev/null 2>&1 || true
  fi
  # Leave $SCRATCH (ISO, keys) for post-mortem inspection on failure; only
  # auto-remove it after a clean pass.
  if [ "${WIZ_TEST_PASSED:-0}" = "1" ]; then
    rm -rf "$SCRATCH"
  else
    echo "Scratch dir preserved for inspection: $SCRATCH" >&2
  fi
}
trap cleanup EXIT

echo "== Generating a throwaway SSH keypair ==" >&2
ssh-keygen -t ed25519 -N "" -C "wizard-vm-test" -f "$SCRATCH/test_key" -q

echo "== Building a scratch checkout with the test key baked in ==" >&2
ISO_BUILD_DIR="$SCRATCH/iso-build-checkout"
mkdir -p "$ISO_BUILD_DIR"
# rsync isn't available in plain Git Bash (only WSL has it) — route the
# copy itself through WSL too, same path-translation as the nix build step
# just below.
REPO_ROOT_WSL="$(to_wsl_path "$REPO_ROOT")"
ISO_BUILD_DIR_WSL="$(to_wsl_path "$ISO_BUILD_DIR")"
wsl -d NixOS -- bash -c "rsync -a --exclude='.git/' --exclude='docs/' '$REPO_ROOT_WSL/' '$ISO_BUILD_DIR_WSL/'"
mkdir -p "$ISO_BUILD_DIR/secrets/extra-files/home/beardedtek/.ssh"
cp "$SCRATCH/test_key.pub" "$ISO_BUILD_DIR/secrets/extra-files/home/beardedtek/.ssh/authorized_keys"

echo "== Building the installer ISO via WSL (this takes a few minutes) ==" >&2
wsl -d NixOS -- bash -c "cd '$ISO_BUILD_DIR_WSL' && nix build --impure --print-build-logs '.#nixosConfigurations.installer.config.system.build.isoImage'"

# `result` is a symlink sitting in the drvfs-mounted checkout dir, but it
# points into WSL's own native Nix store (/nix/store/..., nothing to do
# with the C: drive at all — `realpath --relative-to=/mnt/c` on a path
# that was never under /mnt/c produced "../../nix/store/..." the first
# time this was tried). `find '.../result/iso' -name '*.iso'` follows the
# symlink transparently but prints it back out with the literal
# /mnt/c/.../result prefix it was given, not the resolved native path —
# resolve `result` itself via realpath FIRST so every path from here on is
# the real /nix/store/... location.
ISO_REAL_WSL=$(wsl -d NixOS -- bash -c "realpath '$ISO_BUILD_DIR_WSL/result'")
ISO_PATH_WSL=$(wsl -d NixOS -- bash -c "find '$ISO_REAL_WSL/iso' -name '*.iso' | head -n1")
if [ -z "$ISO_PATH_WSL" ]; then
  echo "TIER 2 FAILED: no .iso found under result/iso after the build." >&2
  exit 1
fi
# WSL2 exposes its whole native filesystem to Windows over
# \\wsl.localhost\<distro>\... — so VirtualBox (a native Windows program)
# can open it directly. Building the literal "\\" prefix via in-string
# "\\\\" escaping was unreliable in testing — empirically collapsed to a
# single backslash regardless of quoting style used. A single-quoted
# `bs='\'` literal is unambiguous (single quotes never interpret
# backslashes), so concatenating that variable is the reliable way to get
# exactly two.
bs='\'
ISO_PATH_WIN="${bs}${bs}wsl.localhost${bs}NixOS$(printf '%s' "$ISO_PATH_WSL" | tr '/' "$bs")"
echo "Built ISO: $ISO_PATH_WIN" >&2

echo "== Creating fresh VM $VM_NAME ==" >&2
"$VBM" createvm --name "$VM_NAME" --ostype "$VM_OSTYPE" --register
VM_CREATED=1
"$VBM" modifyvm "$VM_NAME" \
  --memory "$VM_MEMORY_MB" --cpus "$VM_CPUS" --chipset ich9 --firmware efi \
  --nic1 nat --natpf1 "wizard-test-ssh,tcp,127.0.0.1,$SSH_PORT,,22"
"$VBM" storagectl "$VM_NAME" --name SATA --add sata --controller IntelAhci

echo "== Creating fresh disks (1x ${BOOT_DISK_MB}MB boot, 4x ${POOL_DISK_MB}MB pool) ==" >&2
VM_DISK_DIR="$SCRATCH/vm-disks"
mkdir -p "$VM_DISK_DIR"
VM_DISK_DIR_WIN="$(cygpath -w "$VM_DISK_DIR")"
"$VBM" createmedium disk --filename "$VM_DISK_DIR_WIN\\boot-usb.vdi" --size "$BOOT_DISK_MB" --format VDI
"$VBM" storageattach "$VM_NAME" --storagectl SATA --port 1 --device 0 --type hdd --medium "$VM_DISK_DIR_WIN\\boot-usb.vdi"
for i in 0 1 2 3; do
  "$VBM" createmedium disk --filename "$VM_DISK_DIR_WIN\\pool-disk$i.vdi" --size "$POOL_DISK_MB" --format VDI
  "$VBM" storageattach "$VM_NAME" --storagectl SATA --port "$((i + 2))" --device 0 --type hdd --medium "$VM_DISK_DIR_WIN\\pool-disk$i.vdi"
done

echo "== Attaching the built ISO ==" >&2
"$VBM" storageattach "$VM_NAME" --storagectl SATA --port 0 --device 0 --type dvddrive --medium "$ISO_PATH_WIN"

echo "== Booting $VM_NAME headless ==" >&2
"$VBM" startvm "$VM_NAME" --type headless

ssh_cmd() {
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=5 -i "$SCRATCH/test_key" -p "$SSH_PORT" root@127.0.0.1 "$@"
}

echo "== Waiting for SSH (up to ${BOOT_TIMEOUT_SECS}s) ==" >&2
waited=0
until ssh_cmd true 2>/dev/null; do
  waited=$((waited + 5))
  if [ "$waited" -ge "$BOOT_TIMEOUT_SECS" ]; then
    echo "TIER 2 FAILED: SSH never came up within ${BOOT_TIMEOUT_SECS}s." >&2
    exit 1
  fi
  sleep 5
done
echo "SSH is up after ~${waited}s." >&2

echo "== Discovering real disks (to navigate the 'Boot drive' menu) ==" >&2
# pool_new_list_disks() (lib/pool-new.sh) enumerates /dev/disk/by-id/,
# TYPE=disk only (excludes the optical drive holding this very ISO —
# ata-VBOX_CD-ROM_..., which otherwise shows up right alongside the real
# disks) and *-part* links, sorted alphabetically by name — that exact
# order is what stage_40_storage_new.sh's "Boot drive" whiptail menu lists
# disks in. VirtualBox assigns each VDI's by-id name from a serial we
# don't control, so which position the smallest (boot) disk lands in
# isn't knowable ahead of time — discover it for real here so the
# interaction script below knows how many times to press Down.
DISK_LIST_BY_NAME=$(ssh_cmd "for f in /dev/disk/by-id/*; do case \"\$f\" in *-part*) continue;; esac; [ \"\$(lsblk -ndo TYPE \"\$f\" 2>/dev/null)\" = disk ] || continue; sz=\$(blockdev --getsize64 \"\$f\" 2>/dev/null || echo 0); echo \"\$sz \$(basename \"\$f\")\"; done | sort -k2,2")
DISK_COUNT=$(printf '%s\n' "$DISK_LIST_BY_NAME" | grep -c .)
if [ "$DISK_COUNT" -ne 5 ]; then
  echo "TIER 2 FAILED: expected exactly 5 real disks under /dev/disk/by-id/ on the VM, found $DISK_COUNT." >&2
  printf '%s\n' "$DISK_LIST_BY_NAME" >&2
  exit 1
fi
BOOT_DISK_INDEX=$(printf '%s\n' "$DISK_LIST_BY_NAME" | awk 'BEGIN{min=2^62} {if ($1+0<min){min=$1+0; idx=NR-1}} END{print idx}')
echo "Boot drive (smallest of 5) is at menu position $BOOT_DISK_INDEX (0-based)." >&2

# ---------------------------------------------------------------------
# Drive the REAL run.sh via VirtualBox's own keyboard-injection API.
# configuration.nix's environment.loginShellInit runs
# `sudo bash .../wizard/run.sh` on console login, so this drives the
# exact same session a person sitting at the VM's screen would see.
#
# There's no way to read the console's screen content back through this
# API without OCR, so dialog-to-dialog pacing here is a fixed, generous
# delay (whiptail redraws are near-instant — no real work happens between
# most dialogs) rather than pattern-matched like an `expect` script. The
# two steps that DO involve real, variably-long work — disko and
# nixos-install — are paced by polling a plain, one-shot (non-persistent)
# SSH command for a real on-disk completion signal instead, so this never
# sends the next keystroke while either is still actually running.
# ---------------------------------------------------------------------

vkey_code() { "$VBM" controlvm "$VM_NAME" keyboardputscancode $1 >/dev/null; }
vkey_str() { "$VBM" controlvm "$VM_NAME" keyboardputstring "$1" >/dev/null; }
STEP_DELAY=1.5
vkey_enter() { vkey_code "1c 9c"; sleep "$STEP_DELAY"; }
vkey_space() { vkey_code "39 b9"; sleep "$STEP_DELAY"; }
vkey_down() { vkey_code "e0 50 e0 d0"; sleep "$STEP_DELAY"; }
vkey_right() { vkey_code "e0 4d e0 cd"; sleep "$STEP_DELAY"; }
vkey_text() { vkey_str "$1"; sleep "$STEP_DELAY"; }

wiz_note() { echo "-- progress: $1 --" >&2; }

# Bounded-retry poll of a plain SSH command — same shape as the "Waiting
# for SSH" loop above, reused here for on-disk completion signals instead
# of connectivity.
wait_for_ssh_true() {
  local check="$1" timeout="${2:-120}" waited=0
  until ssh_cmd "$check" 2>/dev/null; do
    waited=$((waited + 5))
    if [ "$waited" -ge "$timeout" ]; then
      echo "TIER 2 FAILED: timed out (${timeout}s) waiting for: $check" >&2
      return 1
    fi
    sleep 5
  done
  return 0
}

echo "== Driving the real installer wizard via VirtualBox keyboard injection ==" >&2
# Give the console's autologin + loginShellInit a moment to actually reach
# run.sh's first whiptail dialog before the first keystroke arrives.
sleep 5

vkey_enter                             # Welcome
vkey_right; vkey_enter                 # Check for updates? -> No (use baked-in snapshot)
vkey_enter                             # LAN interface (only one candidate NIC in this VM)
wiz_note "network configured"

vkey_enter                             # Manufacturer -> accept default "terramaster"
vkey_text "$TEST_INSTANCE"; vkey_enter # Instance name
vkey_enter                             # Hostname -> accept default (= instance name)
vkey_text "$TEST_DOMAIN"; vkey_enter   # Domain
vkey_enter                             # ZFS hostid -> accept the auto-generated default
wiz_note "instance/hostname/domain/hostid set"

vkey_down; vkey_enter                  # Storage -> "new" (2nd item)
for _ in $(seq 1 "$BOOT_DISK_INDEX"); do vkey_down; done
vkey_enter                             # Boot drive
vkey_enter                             # Pool disks -> accept all-ON defaults (blank disks)
vkey_enter                             # RAID level -> accept default "raidz1"
vkey_enter                             # Pool name -> accept default "rust"
sleep 2                                # disko.nix generation + textbox render
vkey_enter                             # dismiss "Generated disko.nix" preview
wiz_note "storage layout selected (new pool, disko.nix generated)"

vkey_text "$TEST_ROOT_PW"; vkey_enter   # Root password
vkey_text "$TEST_ROOT_PW"; vkey_enter   # Confirm root password
vkey_text "testadmin"; vkey_enter       # Add a user
vkey_enter                              # testadmin: sudo access? -> Yes
vkey_text "$TEST_ADMIN_PW"; vkey_enter  # testadmin's password
vkey_text "$TEST_ADMIN_PW"; vkey_enter  # confirm
vkey_text "testuser2"; vkey_enter       # Add a user
vkey_right; vkey_enter                  # testuser2: sudo access? -> No
vkey_text "$TEST_USER2_PW"; vkey_enter  # testuser2's password
vkey_text "$TEST_USER2_PW"; vkey_enter  # confirm
vkey_enter                              # Add a user -> blank name ends the loop
wiz_note "users added (root, testadmin, testuser2)"

# Services checklist: defaults already match this test's "everything but
# minio/filebrowser/immich/zwave" target — minio (index 14), filebrowser
# (index 15), and immich (index 16) all default OFF and are consecutive
# in the checklist's current order (hosts/installer/wizard/stages/60-features.sh),
# so one run of downs reaches all three. Immich is toggled on for the
# same reason minio is: exercises the rust/<name> dataset-creation
# safety net (see hosts/installer/wizard/lib/generate-config.sh's
# _gen_zfs_ensure_block) rather than leaving it untested at its OFF
# default.
for _ in $(seq 1 14); do vkey_down; done
vkey_space
vkey_down; vkey_space
vkey_down; vkey_space
vkey_enter
wiz_note "services selected"

vkey_down; vkey_down; vkey_enter # SSH access -> "password" (3rd item)
vkey_enter                       # Use password login? -> Yes
vkey_right; vkey_enter           # Nebula? -> No
vkey_text "$TEST_LDAP_PW"; vkey_enter # LLDAP admin password
vkey_text "$TEST_LDAP_PW"; vkey_enter # confirm
wiz_note "secrets stage done (SSH access, Nebula skipped, LLDAP admin pw set)"

vkey_enter                        # Review
vkey_text "DESTROY"; vkey_enter   # typed destructive confirmation
wiz_note "destructive confirmation typed — install starting"

vkey_enter # "Writing config"
sleep 2
vkey_enter # "Running disko" -> triggers the real pool_new_run_disko
wiz_note "disko running (real destroy/format/mount against the VM's disks)"
wait_for_ssh_true "mountpoint -q /mnt/persist" 120 || exit 1
sleep 3 # secret generation + the /persist bind-mount, both near-instant

vkey_enter # "Installing NixOS" -> triggers the real nixos-install
wiz_note "nixos-install running (this is the long step — several minutes)"
wait_for_ssh_true "test -d /mnt/persist/nixos-installer-output" 1800 || exit 1
wiz_note "nixos-install finished successfully"

sleep 2
vkey_enter # "Done"
# Always decline the wizard's own reboot, even under WIZ_TEST_KEEP_VM=1 —
# letting the *guest* trigger `reboot` races this script's own detach step
# below (the DVD port doesn't support hot-plug — confirmed the hard way,
# "does not support hot-plugging" — so the ISO has to come off while the
# VM is fully powered off, not live). Declining here and driving the
# power-cycle from the host side instead is deterministic.
vkey_right && vkey_enter # "Reboot now?" -> No

if [ "$WIZ_TEST_KEEP_VM" = "1" ]; then
  wiz_note "WIZ_TEST_KEEP_VM=1 — power-cycling into the installed system (detaching the ISO first)"
  "$VBM" controlvm "$VM_NAME" poweroff >/dev/null 2>&1
  sleep 3
  # Firmware boot order tries the DVD drive before the hard disk — left
  # attached, this would just boot straight back into the live installer
  # instead of the system that was just installed (hit exactly this the
  # first time this flag was used, manually, before this was scripted).
  "$VBM" storageattach "$VM_NAME" --storagectl SATA --port 0 --device 0 --type dvddrive --medium none
  "$VBM" startvm "$VM_NAME" --type headless
fi

echo >&2
echo "TIER 2 PASSED: the real installer wizard completed against the VM's real disks." >&2
WIZ_TEST_PASSED=1
