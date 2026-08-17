#!/usr/bin/env bash
# shellcheck disable=SC2016
# ^ every single-quoted jq filter below intentionally holds jq's OWN
#   $var syntax (bound via --arg/--argjson), not bash expansion — that's
#   the whole point of quoting them.
#
# Browser-backed wiz_* primitives (WIZ_UI_BACKEND=web). Every stage file
# calls these exact same function names as the whiptail backend
# (lib/ui-tui.sh) — this is the third implementation of the seam
# lib/test/lib/mock-wiz.sh already proved works for testing, now used for
# real. No stage file needed any change to support this.
#
# Protocol: a single canonical file per question, atomically rewritten,
# polled by both sides — not a FIFO (couples a specific reader to a
# specific writer at call time; a stale/duplicate CGI request would hang
# with nobody home) and not a lock-protected shared-memory scheme. This
# mirrors this repo's own existing idiom for durable small runtime state
# (modules/dashboard-login.nix's session-token files,
# modules/self-update.nix's request.json/progress.json under
# /run/system-rebuild/).
#
# $WIZ_RUN_DIR/question.json is the current "what's being asked"
# descriptor — every wiz_* call increments a sequence number, writes a
# fresh question.json (atomic .tmp + mv, so a GET never observes a
# half-written file), then blocks polling for
# $WIZ_RUN_DIR/answer-<seq>.json to appear (written by the
# POST /api/answer CGI, hosts/installer/wizard/cgi/answer.sh). That CGI
# rejects any POST whose seq doesn't match the CURRENT question.json's
# seq — the sole defense against a stale/duplicate submission (browser
# back-button, page refresh, a slow double-click): it's simply not
# "the current question" anymore, so it's ignored rather than corrupting
# state, and the frontend just re-renders whatever's actually current.
#
# Retry-loop stages (50-users.sh's password double-entry, 65-smtp.sh,
# 70-secrets.sh's SSH-key loop) need NO special handling here — a
# validation failure is just the stage script calling wiz_msgbox (a new
# question) and then looping back to call wiz_password again (a new seq,
# a new question.json). The protocol has no notion of "the same form,"
# only "the current thing to show" — indistinguishable, at this layer,
# from any other sequential question.

: "${WIZ_UI_POLL_INTERVAL:=0.3}"

# Builds+writes question.json, blocks until the matching answer file
# exists, then prints its raw JSON on stdout (each wrapper below parses
# out just the field(s) it needs) and removes it. $@ is passed straight
# to `jq -n` and must produce an object with at least a "type" key — that
# becomes the envelope's "question" field.
_wiz_web_ask() {
  wiz_claim_or_die "web"
  mkdir -p "$WIZ_RUN_DIR"

  local seq
  seq=$(( $(cat "$WIZ_RUN_DIR/seq" 2>/dev/null || echo 0) + 1 ))
  printf '%s' "$seq" > "$WIZ_RUN_DIR/seq"

  # Defensive cleanup of anything orphaned from a prior seq (e.g. a
  # duplicate POST that arrived after its own question was superseded).
  rm -f "$WIZ_RUN_DIR"/answer-*.json

  local question_json
  question_json=$(jq -n "$@")

  jq -n --argjson seq "$seq" --arg stage "${WIZ_CURRENT_STAGE:-}" --argjson question "$question_json" \
    '{session_state:"active", claimed_by:"web", seq:$seq, stage:$stage, question:$question}' \
    > "$WIZ_RUN_DIR/question.json.tmp"
  mv "$WIZ_RUN_DIR/question.json.tmp" "$WIZ_RUN_DIR/question.json"

  local answer_file="$WIZ_RUN_DIR/answer-$seq.json"
  while [ ! -f "$answer_file" ]; do
    sleep "$WIZ_UI_POLL_INTERVAL"
  done

  cat "$answer_file"
  rm -f "$answer_file"
}

# {"cancelled":true} maps to the same wiz_abort path a whiptail Cancel
# already triggers — cancel semantics stay unified across backends.
_wiz_web_die_if_cancelled() {
  local answer="$1" title="$2"
  if [ "$(printf '%s' "$answer" | jq -r '.cancelled // false')" = "true" ]; then
    wiz_abort "Cancelled at: $title"
  fi
}

wiz_msgbox() {
  local title="$1" message="$2"
  _wiz_web_ask --arg title "$title" --arg message "$message" \
    '{type:"msgbox", title:$title, message:$message, error:null}' >/dev/null
}

wiz_yesno() {
  local title="$1" message="$2" answer value
  answer=$(_wiz_web_ask --arg title "$title" --arg message "$message" \
    '{type:"yesno", title:$title, message:$message, error:null}')
  value=$(printf '%s' "$answer" | jq -r '.value // false')
  [ "$value" = "true" ]
}

# Prints the entered value on stdout; caller captures it.
wiz_input() {
  local title="$1" prompt="$2" default="${3:-}" answer
  answer=$(_wiz_web_ask --arg title "$title" --arg prompt "$prompt" --arg default "$default" \
    '{type:"input", title:$title, prompt:$prompt, default:$default, error:null}')
  _wiz_web_die_if_cancelled "$answer" "$title"
  printf '%s' "$answer" | jq -r '.value // empty'
}

wiz_password() {
  local title="$1" prompt="$2" answer
  answer=$(_wiz_web_ask --arg title "$title" --arg prompt "$prompt" \
    '{type:"password", title:$title, prompt:$prompt, error:null}')
  _wiz_web_die_if_cancelled "$answer" "$title"
  printf '%s' "$answer" | jq -r '.value // empty'
}

# $2 is a whiptail-style flat list: "tag1" "description1" "tag2" "description2" ...
wiz_menu() {
  local title="$1" prompt="$2" answer
  shift 2
  local options_json="[]"
  while [ "$#" -ge 2 ]; do
    options_json=$(printf '%s' "$options_json" | jq --arg tag "$1" --arg label "$2" '. + [{tag:$tag, label:$label}]')
    shift 2
  done
  answer=$(_wiz_web_ask --arg title "$title" --arg prompt "$prompt" --argjson options "$options_json" \
    '{type:"menu", title:$title, prompt:$prompt, options:$options, error:null}')
  _wiz_web_die_if_cancelled "$answer" "$title"
  printf '%s' "$answer" | jq -r '.value // empty'
}

# $2 is a whiptail checklist list: "tag1" "description1" "OFF" ...
# Prints space-separated, double-quoted selected tags — matching
# whiptail's own output convention exactly, since every existing caller
# (e.g. stages/40-storage-new.sh) already parses that exact shape.
wiz_checklist() {
  local title="$1" prompt="$2" answer
  shift 2
  local options_json="[]"
  while [ "$#" -ge 3 ]; do
    local checked="false"
    [ "$3" = "ON" ] && checked="true"
    options_json=$(printf '%s' "$options_json" | jq --arg tag "$1" --arg label "$2" --argjson checked "$checked" '. + [{tag:$tag, label:$label, checked:$checked}]')
    shift 3
  done
  answer=$(_wiz_web_ask --arg title "$title" --arg prompt "$prompt" --argjson options "$options_json" \
    '{type:"checklist", title:$title, prompt:$prompt, options:$options, error:null}')
  _wiz_web_die_if_cancelled "$answer" "$title"
  printf '%s' "$answer" | jq -r '(.value // []) | map("\"" + . + "\"") | join(" ")'
}

# Shows a file's contents read-only, served from a fixed path — there's
# only ever one blocking question at a time (single wizard process), so
# no per-call uniqueness is needed and a fixed filename avoids any
# path-traversal surface in the nginx location that serves it.
wiz_textbox() {
  local title="$1" file="$2"
  cp "$file" "$WIZ_RUN_DIR/textbox-current.txt"
  _wiz_web_ask --arg title "$title" --arg content_url "/api/textbox/current" \
    '{type:"textbox", title:$title, content_url:$content_url, error:null}' >/dev/null
}

# A pure progress waypoint (stages/90-install.sh's "Writing config"/
# "Running disko"/"Installing NixOS" announcements) — deliberately does
# NOT block on a question/answer round-trip, unlike every other primitive
# here. These are redundant with the live step-list the frontend already
# renders from /api/install-progress once stage_90_install starts (a
# wiz_progress call sits right next to every wiz_notice call in that
# stage file) — surfacing them as a second, click-to-continue card on top
# of that panel is exactly the friction reported after actually using
# this: a message that requires an unnecessary click before real
# background work (disko, nixos-install) even starts. Still captured into
# install.log (via _wiz_notice_log) so the log panel isn't blank during
# the stretch before nixos-install's own output starts flowing into that
# same file.
#
# Still writes question.json (with question:null) rather than touching
# nothing at all: that's the ONLY thing that updates the envelope's
# "stage" field, which is how the frontend notices stage_90_install has
# begun at all and shows the progress panel. Without this, "stage" would
# stay stuck at whatever the last real blocking call's stage was
# (stage_80_review) for the entire disko/secrets/nixos-install stretch,
# and the progress panel wouldn't appear until the final "Done" msgbox —
# confirmed by re-reading this file's own design before it shipped, not
# against a real symptom.
wiz_notice() {
  wiz_claim_or_die "web"
  _wiz_notice_log "$1" "$2"

  local seq
  seq=$(( $(cat "$WIZ_RUN_DIR/seq" 2>/dev/null || echo 0) + 1 ))
  printf '%s' "$seq" > "$WIZ_RUN_DIR/seq"
  jq -n --argjson seq "$seq" --arg stage "${WIZ_CURRENT_STAGE:-}" \
    '{session_state:"active", claimed_by:"web", seq:$seq, stage:$stage, question:null}' \
    > "$WIZ_RUN_DIR/question.json.tmp"
  mv "$WIZ_RUN_DIR/question.json.tmp" "$WIZ_RUN_DIR/question.json"
}

# Multi-line paste (e.g. stages/70-secrets.sh's Nebula config.yaml/certs)
# — the one thing a browser can do that a TUI genuinely can't (see
# lib/ui-tui.sh's wiz_textarea, which just points the operator here
# instead). Same protocol shape as wiz_input, just a different "type" so
# the frontend renders a <textarea> instead of a single-line <input>.
wiz_textarea() {
  local title="$1" prompt="$2" answer
  answer=$(_wiz_web_ask --arg title "$title" --arg prompt "$prompt" \
    '{type:"textarea", title:$title, prompt:$prompt, error:null}')
  _wiz_web_die_if_cancelled "$answer" "$title"
  printf '%s' "$answer" | jq -r '.value // empty'
}
