#!/usr/bin/env bash
# GET /api/install-progress — collapses stages/90-install.sh's append-only
# wiz_progress() checkpoint log (write-config -> disko -> secrets ->
# nixos-install -> done) into a step-list + log-tail snapshot the WebUI's
# install screen polls. Modeled on modules/self-update.nix's own
# "settled snapshot from an append log" statusCgi pattern — every step's
# most RECENT event wins (a step goes running -> done/failed).

set -euo pipefail

WIZ_RUN_DIR="${WIZ_RUN_DIR:-/run/wiz-web}"
PROGRESS_FILE="$WIZ_RUN_DIR/install-progress.jsonl"
LOG_FILE="$WIZ_RUN_DIR/install.log"

printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'

if [ ! -f "$PROGRESS_FILE" ]; then
  printf '{"state":"pending","steps":[],"logTail":""}\n'
  exit 0
fi

log_tail=""
[ -f "$LOG_FILE" ] && log_tail=$(tail -c 8192 "$LOG_FILE")

jq -n --slurpfile events "$PROGRESS_FILE" --arg logTail "$log_tail" '
  ($events // []) as $ev
  | ["write-config","disko","secrets","nixos-install","done"] as $order
  | {
      "write-config":"Writing configuration",
      "disko":"Partitioning & formatting disks",
      "secrets":"Generating secrets",
      "nixos-install":"Installing NixOS",
      "done":"Done"
    } as $labels
  | ($order | map(
      . as $key
      | ($ev | map(select(.step == $key)) | if length > 0 then last.state else "pending" end) as $state
      | {key:$key, label:$labels[$key], state:$state}
    )) as $steps
  | (
      if ($steps | map(select(.state=="failed")) | length) > 0 then "failed"
      elif ($steps | map(select(.state=="running")) | length) > 0 then "running"
      elif ($steps[-1].state == "done") then "done"
      else "pending"
      end
    ) as $overall
  | {state:$overall, steps:$steps, logTail:$logTail}
'
