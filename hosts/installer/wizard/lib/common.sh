#!/usr/bin/env bash
# Shared helpers sourced by every wizard stage. Not directly executable.

declare -gA WIZ=()

wiz_set() { WIZ["$1"]="$2"; }
wiz_get() { printf '%s' "${WIZ[$1]:-}"; }

WHIPTAIL_BACKTITLE="TerraMaster-family NAS installer"

# The baked-in repo copy lives here (see hosts/installer/configuration.nix
# — environment.etc."nas-installer-repo" points at the flake's own `self`).
# Copied to WIZ_REPO_WORKDIR (writable) before the wizard generates
# anything into it, optionally refreshed from WIZ_REPO_URL first.
: "${WIZ_REPO_BAKED_IN:=/etc/nas-installer-repo}"
: "${WIZ_REPO_WORKDIR:=/root/terramaster-nix}"
: "${WIZ_REPO_URL:=https://github.com/BeardedTek/terramaster-nix.git}"

wiz_msgbox() {
  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "$1" --msgbox "$2" 20 76
}

wiz_yesno() {
  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "$1" --yesno "$2" 20 76
}

# Prints the entered value on stdout; caller captures it. Exits the wizard
# (not just the stage) if the user cancels — every prompt in this wizard is
# required, there's no "skip" state to fall back to mid-flow.
wiz_input() {
  local title="$1" prompt="$2" default="${3:-}"
  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "$title" \
    --inputbox "$prompt" 20 76 "$default" 3>&1 1>&2 2>&3 \
    || wiz_abort "Cancelled at: $title"
}

wiz_password() {
  local title="$1" prompt="$2"
  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "$title" \
    --passwordbox "$prompt" 20 76 3>&1 1>&2 2>&3 \
    || wiz_abort "Cancelled at: $title"
}

# $2 is a whiptail-style flat list: "tag1" "description1" "tag2" "description2" ...
wiz_menu() {
  local title="$1" prompt="$2"
  shift 2
  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "$title" \
    --menu "$prompt" 20 76 10 "$@" 3>&1 1>&2 2>&3 \
    || wiz_abort "Cancelled at: $title"
}

# $2 is a whiptail checklist list: "tag1" "description1" "OFF" ...
# Prints space-separated selected tags (whiptail's own quoting) on stdout.
wiz_checklist() {
  local title="$1" prompt="$2"
  shift 2
  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "$title" \
    --checklist "$prompt" 24 76 12 "$@" 3>&1 1>&2 2>&3 \
    || wiz_abort "Cancelled at: $title"
}

wiz_abort() {
  echo "Installer wizard aborted: ${1:-cancelled by user}" >&2
  clear
  exit 1
}

wiz_die() {
  wiz_msgbox "Error" "$1"
  wiz_abort "$1"
}

# Requires the user to type $2 verbatim to continue. Used for destructive
# confirmations — a yes/no dialog is too easy to reflexively click through.
wiz_type_to_confirm() {
  local prompt="$1" required="$2" typed
  typed=$(wiz_input "Confirm" "$prompt

Type $required (all caps, exactly) to continue.")
  [ "$typed" = "$required" ]
}
