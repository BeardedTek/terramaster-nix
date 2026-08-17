#!/usr/bin/env bash
# Mutual exclusion between the TUI and WebUI backends — whichever one
# actually starts driving the wizard first (i.e. reaches its first
# wiz_* call) claims the whole install session; the other is blocked
# outright. Symmetric: neither backend has priority, purely first-come —
# environment.loginShellInit already launches a fresh TUI on every
# console login (tty1-6, or SSH) same as before, and the WebUI's own
# systemd service starts independently at boot, so both sides reach
# their first wiz_* call at whatever moment a human actually starts
# answering questions on that interface.
#
# flock, not a PID file: the advisory lock is tied to the open file
# descriptor, so if the holding process dies for any reason (crash, kill,
# console reset) the kernel releases it automatically — no "is that PID
# still alive, and is it still really this wizard" staleness logic to
# write or get wrong. $WIZ_RUN_DIR is tmpfs and fresh every boot, so
# there's no cross-boot staleness either.

WIZ_CLAIMED=""

wiz_claim_or_die() {
  local backend="$1"
  [ -n "$WIZ_CLAIMED" ] && return 0

  mkdir -p "$WIZ_RUN_DIR"
  exec 9>>"$WIZ_RUN_DIR/lock"
  if flock -n 9; then
    WIZ_CLAIMED=1
    printf '%s' "$backend" > "$WIZ_RUN_DIR/claimed-by"
    return 0
  fi

  local other
  other=$(cat "$WIZ_RUN_DIR/claimed-by" 2>/dev/null || echo "the other interface")

  if [ "$backend" = "web" ]; then
    # A terminal state for any browser already polling — question.json is
    # otherwise owned exclusively by whichever process actually won.
    jq -n --arg by "$other" \
      '{session_state:"lost", claimed_by:$by, seq:0, stage:null, question:null}' \
      > "$WIZ_RUN_DIR/question.json.tmp"
    mv "$WIZ_RUN_DIR/question.json.tmp" "$WIZ_RUN_DIR/question.json"
    echo "wiz-web: install already in progress via $other — refusing to start a second session." >&2
    exit 1
  else
    whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "Already in progress" \
      --msgbox "The installer is already being driven from the $other interface. This console session will exit — continue there." 10 70 || true
    clear
    exit 1
  fi
}
