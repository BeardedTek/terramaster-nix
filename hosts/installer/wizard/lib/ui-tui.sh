#!/usr/bin/env bash
# whiptail-backed wiz_* primitives — the original, default backend
# (WIZ_UI_BACKEND=tui, run.sh's default). Every function claims the
# shared TUI/WebUI lock (lib/wiz-claim.sh) before doing anything else, so
# a WebUI session started first blocks this one outright instead of
# racing it.

wiz_msgbox() {
  wiz_claim_or_die "tui"
  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "$1" --msgbox "$2" 20 76
}

wiz_yesno() {
  wiz_claim_or_die "tui"
  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "$1" --yesno "$2" 20 76
}

# Prints the entered value on stdout; caller captures it. Exits the wizard
# (not just the stage) if the user cancels — every prompt in this wizard is
# required, there's no "skip" state to fall back to mid-flow.
wiz_input() {
  wiz_claim_or_die "tui"
  local title="$1" prompt="$2" default="${3:-}"
  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "$title" \
    --inputbox "$prompt" 20 76 "$default" 3>&1 1>&2 2>&3 \
    || wiz_abort "Cancelled at: $title"
}

wiz_password() {
  wiz_claim_or_die "tui"
  local title="$1" prompt="$2"
  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "$title" \
    --passwordbox "$prompt" 20 76 3>&1 1>&2 2>&3 \
    || wiz_abort "Cancelled at: $title"
}

# $2 is a whiptail-style flat list: "tag1" "description1" "tag2" "description2" ...
wiz_menu() {
  wiz_claim_or_die "tui"
  local title="$1" prompt="$2"
  shift 2
  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "$title" \
    --menu "$prompt" 20 76 10 "$@" 3>&1 1>&2 2>&3 \
    || wiz_abort "Cancelled at: $title"
}

# $2 is a whiptail checklist list: "tag1" "description1" "OFF" ...
# Prints space-separated selected tags (whiptail's own quoting) on stdout.
wiz_checklist() {
  wiz_claim_or_die "tui"
  local title="$1" prompt="$2"
  shift 2
  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "$title" \
    --checklist "$prompt" 24 76 12 "$@" 3>&1 1>&2 2>&3 \
    || wiz_abort "Cancelled at: $title"
}

# Shows a file's contents read-only. Used by stages/40-storage-new.sh to
# preview the disko.nix it just generated before the destructive
# confirmation later in stages/80-review.sh.
wiz_textbox() {
  wiz_claim_or_die "tui"
  local title="$1" file="$2"
  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "$title" --textbox "$file" 30 90
}

# A pure progress waypoint (stages/90-install.sh's "Writing config"/
# "Running disko"/"Installing NixOS" announcements) — unlike wiz_msgbox,
# not meant to convey anything a user must specifically read and
# acknowledge, just "here's what's happening now." Still a real blocking
# whiptail msgbox here: the TUI has no separate progress panel the way
# the web backend's install screen does (see lib/ui-web.sh's own
# wiz_notice), so this remains the TUI's only way to show phase changes.
wiz_notice() {
  wiz_claim_or_die "tui"
  _wiz_notice_log "$1" "$2"
  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "$1" --msgbox "$2" 20 76
}

# Multi-line paste (e.g. stages/70-secrets.sh's Nebula config.yaml/certs).
# whiptail has no real multi-line-paste widget suited to this (its
# --scrolltext/--textbox are read-only), so the TUI falls back to
# directing the operator elsewhere rather than attempting something
# unreliable over a terminal paste. wiz_input remains available for
# short, single-line values.
wiz_textarea() {
  wiz_claim_or_die "tui"
  local title="$1"
  wiz_msgbox "Not available here" "Pasting multi-line content (\"$title\") isn't supported in this console — use the WebUI instead (see the URL printed at login), or configure this manually after install."
  printf ''
}
