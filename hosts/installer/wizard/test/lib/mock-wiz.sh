#!/usr/bin/env bash
# Overrides every wiz_* UI primitive (lib/common.sh) with a test double
# that returns a scripted answer instead of launching whiptail. Answers
# are keyed by dialog TITLE (each wiz_* call's first argument) rather
# than call order — more robust to the stages being reordered slightly,
# and a missing answer fails loudly with the exact title that needs one
# instead of a silently-misaligned queue.
#
# Most titles are unique per run (scalar MOCK_ANSWERS), but a few dialogs
# fire multiple times with the SAME title and need DIFFERENT answers each
# time (currently just 50-users.sh's "Add a user" loop) — those go in
# MOCK_ANSWER_QUEUES instead, a newline-separated list consumed one line
# per call.
#
# Queued answers are tracked as FILES (one per title, under
# MOCK_QUEUE_DIR), not a plain shell array element, despite MOCK_ANSWER_QUEUES
# itself being how the fixture declares them — every wiz_input/wiz_menu/
# etc. call is invoked by the real stage code as `x=$(wiz_input ...)`,
# and $(...) command substitution always forks a subshell. Any state a
# mock tried to persist by mutating a shell array *inside* that call would
# be silently discarded the instant the subshell exits, back in the
# parent — confirmed the hard way: the first version of this mock kept
# "popping" the same first answer forever, because the pop only ever
# happened in a subshell nobody kept. Real file writes aren't scoped to
# the subshell that made them, so they're the one thing here that
# actually survives back to the next call.

declare -gA MOCK_ANSWERS=()
declare -gA MOCK_YESNO=()
declare -gA MOCK_ANSWER_QUEUES=()

MOCK_QUEUE_DIR="$(mktemp -d)"
_mock_cleanup_queue_dir() { rm -rf "$MOCK_QUEUE_DIR"; }
trap _mock_cleanup_queue_dir EXIT

_mock_queue_filename() {
  # A safe, collision-resistant filename from an arbitrary title string.
  printf '%s' "$1" | cksum | cut -d' ' -f1
}

# Call once, after sourcing a fixture (which populates MOCK_ANSWER_QUEUES
# as plain associative-array values) and before calling any stage —
# materializes each queued title's answers as a file so _mock_pop_or_scalar
# can consume them one at a time across however many subshells that takes.
mock_wiz_init_queues() {
  local title
  for title in "${!MOCK_ANSWER_QUEUES[@]}"; do
    printf '%s' "${MOCK_ANSWER_QUEUES[$title]}" > "$MOCK_QUEUE_DIR/$(_mock_queue_filename "$title")"
  done
}

_mock_missing() {
  echo "mock-wiz: no scripted answer for $1 '$2' — add one to the fixture." >&2
  exit 1
}

# Pops one line off a queued title's remaining answers (via its file);
# leaves the rest for the next call. Falls back to the plain scalar map
# if this title was never queued at all.
_mock_pop_or_scalar() {
  local title="$1"
  local qfile="$MOCK_QUEUE_DIR/$(_mock_queue_filename "$title")"
  if [ -f "$qfile" ]; then
    local queue head rest
    queue="$(cat "$qfile")"
    head="${queue%%$'\n'*}"
    if [ "$head" = "$queue" ]; then
      rest=""
    else
      rest="${queue#*$'\n'}"
    fi
    printf '%s' "$rest" > "$qfile"
    printf '%s' "$head"
    return 0
  fi
  [ -n "${MOCK_ANSWERS[$title]+x}" ] || _mock_missing "input" "$title"
  printf '%s' "${MOCK_ANSWERS[$title]}"
}

wiz_msgbox() { :; }

wiz_yesno() {
  local title="$1"
  [ -n "${MOCK_YESNO[$title]+x}" ] || _mock_missing "yesno" "$title"
  [ "${MOCK_YESNO[$title]}" = "true" ]
}

wiz_input() { _mock_pop_or_scalar "$1"; }
wiz_password() { _mock_pop_or_scalar "$1"; }
wiz_menu() { _mock_pop_or_scalar "$1"; }
wiz_checklist() { _mock_pop_or_scalar "$1"; }
# Empty by default (matches the "skip — nothing pasted" path every
# existing fixture exercises); add a scalar/queued answer for a specific
# title the same way as wiz_input if a fixture ever needs to test the
# "something was pasted" branch.
wiz_textarea() { [ -n "${MOCK_ANSWERS[$1]+x}" ] && _mock_pop_or_scalar "$1" || printf ''; }
# Pure progress waypoint — nothing to script an answer for (see
# lib/ui-web.sh's own wiz_notice comment).
wiz_notice() { :; }

wiz_die() {
  echo "mock-wiz: wiz_die: ${1:-}" >&2
  exit 1
}

wiz_abort() {
  echo "mock-wiz: wiz_abort: ${1:-cancelled}" >&2
  exit 1
}

# stages/40-storage-new.sh's generated-disko.nix preview — a plain
# read-only display, nothing to script an answer for.
wiz_textbox() { :; }
