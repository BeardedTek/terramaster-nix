#!/usr/bin/env bash
# POST /api/answer — the one real CGI in the WebUI installer's IPC
# protocol (see hosts/installer/wizard/lib/ui-web.sh's header comment for
# the full picture). Writes the POSTed body to
# $WIZ_RUN_DIR/answer-<seq>.json, unblocking whichever wiz_* call is
# currently polling for it — but ONLY if the posted seq matches the
# CURRENT question.json's seq. That's the sole defense against a
# stale/duplicate submission (browser back-button, page refresh, a slow
# double-click): anything else is rejected with 409 and the real current
# question, which the frontend treats identically to a normal poll
# response — no special-case retry/error logic needed there.

set -euo pipefail

WIZ_RUN_DIR="${WIZ_RUN_DIR:-/run/wiz-web}"
QUESTION_FILE="$WIZ_RUN_DIR/question.json"

fail_bad_request() {
  printf 'Status: 400 Bad Request\r\nContent-Type: application/json\r\n\r\n{"error":"bad request"}\n'
  exit 0
}

content_length="${CONTENT_LENGTH:-0}"
case "$content_length" in
  ''|*[!0-9]*) fail_bad_request ;;
esac
# 1MiB is generously above anything this wizard would ever legitimately
# send (even the largest checklist selection is a handful of short tags).
[ "$content_length" -gt 0 ] && [ "$content_length" -le 1048576 ] || fail_bad_request

body=$(head -c "$content_length")

posted_seq=$(printf '%s' "$body" | jq -r '.seq // empty' 2>/dev/null || true)
# Purely-digits check, before this ever becomes part of a file path below.
case "$posted_seq" in
  ''|*[!0-9]*) fail_bad_request ;;
esac

current_seq=""
if [ -f "$QUESTION_FILE" ]; then
  current_seq=$(jq -r '.seq // empty' "$QUESTION_FILE" 2>/dev/null || true)
fi

if [ -z "$current_seq" ] || [ "$posted_seq" != "$current_seq" ]; then
  printf 'Status: 409 Conflict\r\nContent-Type: application/json\r\n\r\n'
  if [ -f "$QUESTION_FILE" ]; then
    cat "$QUESTION_FILE"
  else
    printf '{"session_state":"unknown"}\n'
  fi
  exit 0
fi

answer_file="$WIZ_RUN_DIR/answer-${posted_seq}.json"
printf '%s' "$body" > "${answer_file}.tmp"
mv "${answer_file}.tmp" "$answer_file"
printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n{"ok":true}\n'
