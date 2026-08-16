#!/usr/bin/env bash
# Tier 3, part A: gets a running, fully-featured installed VM (by sourcing
# run-vm-install.sh's tier2_run_and_install_wizard, the same "everything
# but Z-Wave" install Tier 2 itself now does) and opens one SSH connection
# with local port-forwards for every enabled service's backend port plus
# Traefik's own :443 — then prints a JSON manifest of URLs to check.
#
# This script does NOT drive Chrome DevTools MCP itself — those tools are
# only callable from the Claude session driving this whole test, not from
# a bash subprocess. Run this script, then have Claude read the manifest
# ($WIZ_TIER3_MANIFEST, printed at the end) and drive
# navigate_page/take_snapshot/list_console_messages/list_network_requests
# against each URL in it.
#
# Two paths, per URL:
#   - "direct": http://127.0.0.1:<tunnel-port>/ straight to the service's
#     own backend port over the SSH tunnel — bypasses Traefik/TLS/SSO
#     entirely, so it works with zero extra setup. Confirms the service
#     itself is up and serving its own UI.
#   - "vhost": https://<svc>.wiztest.test.invalid:18443/ through Traefik's
#     real router/TLS/SSO layer, tunneled the same way. SNI/Host-based
#     routing works fine against Traefik's self-signed fallback cert even
#     though ACME/DNS-01 can never succeed for the "test.invalid" domain
#     (RFC 2606, never delegated) — router matching doesn't depend on
#     certificate validity. Needs TWO one-time local prerequisites this
#     script can't set up itself (see the printed manifest's
#     "vhost_prereqs" field):
#       1. One line per vhost name in
#          C:\Windows\System32\drivers\etc\hosts pointing at 127.0.0.1
#          (Windows' hosts file has no wildcard support, and needs an
#          admin-elevated edit — a system-file change this script
#          deliberately doesn't make on its own).
#       2. Chrome needs cert-error-ignoring enabled so a self-signed vhost
#          cert doesn't block navigation — the chrome-devtools MCP server
#          (npx chrome-devtools-mcp@latest, confirmed via its own --help)
#          exposes this as a real, documented --accept-insecure-certs CLI
#          flag. This script re-registers that server with the flag added
#          (via `claude mcp`, the same CLI Claude Code itself uses) before
#          running — see chrome_mcp_restore()/chrome_mcp_swap_in() below.
#          This only changes the *registration*; the actual running Chrome
#          instance a live Claude Code session already has open doesn't
#          pick up the new flag until that session reconnects the
#          chrome-devtools server (the /mcp command, or a session
#          restart) — do that once after this script prints "TIER 3
#          READY", before driving any vhost checks.
#
#          Confirmed in a real Part B run: even with the flag active and
#          reconnected, chrome-devtools-mcp accepted the apex vhost's
#          self-signed cert but consistently refused every subdomain
#          vhost's identical cert with ERR_CERT_AUTHORITY_INVALID — a
#          chrome-devtools-mcp/Puppeteer-side quirk, not a real product
#          issue (verified via `curl -k --resolve <name>:18443:127.0.0.1
#          https://<name>:18443/`, which succeeds cleanly for every
#          vhost and shows correct Traefik routing/Authelia ForwardAuth
#          redirects). If Part B hits this, fall back to curl for the
#          affected vhosts rather than assuming the service is broken.
#
#          This registration swap is NOT undone automatically when this
#          script's own process exits on success — Part B (driving
#          Chrome DevTools MCP) runs afterward, in an entirely separate
#          process (the calling Claude session), so there is nothing in
#          this script's own lifetime to tie an automatic restore to.
#          Confirmed the hard way: an earlier version restored
#          unconditionally in its EXIT trap, which fired the moment
#          Part A finished — long before Part B (run interactively,
#          afterward) ever got a chance to use the swapped-in flag at
#          all. It DOES restore automatically on any FAILURE exit before
#          reaching "TIER 3 READY", since there's no Part B to wait for
#          in that case. On success, restore it yourself once Part B is
#          done:
#            claude mcp remove chrome-devtools -s local
#            claude mcp add chrome-devtools -s user -- npx chrome-devtools-mcp@latest
#          (then reconnect the MCP server once more).
#
# Run from Git Bash on the Windows host, same as Tier 2:
#   bash hosts/installer/wizard/test/run-webui-check.sh
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=run-vm-install.sh
source "$TEST_DIR/run-vm-install.sh"

# The chrome-devtools MCP server's normal, permanent registration —
# confirmed via `claude mcp get chrome-devtools` before writing this
# (user scope, plain `npx chrome-devtools-mcp@latest`, no extra args).
# Update these if that server's real base config ever changes.
CHROME_MCP_NAME="chrome-devtools"
CHROME_MCP_RESTORE_SCOPE="user"
CHROME_MCP_RESTORE_CMD=(npx chrome-devtools-mcp@latest)

# Idempotent — safe to call even if a previous crashed run already left
# things in the restored state, or never got as far as swapping at all.
chrome_mcp_restore() {
  claude mcp remove "$CHROME_MCP_NAME" -s local >/dev/null 2>&1 || true
  claude mcp remove "$CHROME_MCP_NAME" -s "$CHROME_MCP_RESTORE_SCOPE" >/dev/null 2>&1 || true
  claude mcp add "$CHROME_MCP_NAME" -s "$CHROME_MCP_RESTORE_SCOPE" -- "${CHROME_MCP_RESTORE_CMD[@]}" >/dev/null 2>&1 || true
}

chrome_mcp_swap_in() {
  echo "== Temporarily re-registering the $CHROME_MCP_NAME MCP server with --accept-insecure-certs (for the vhost/TLS checks) ==" >&2
  # Restore-then-swap rather than a plain remove+add: self-heals a stale
  # local-scope leftover from an earlier crashed run before creating a
  # fresh one, and removing the user-scope entry first means there's
  # never more than one registration for this name at once — no scope-
  # precedence ambiguity to reason about.
  chrome_mcp_restore
  claude mcp add "$CHROME_MCP_NAME" -s local -- npx chrome-devtools-mcp@latest --accept-insecure-certs
  echo "NOTE: reconnect the $CHROME_MCP_NAME MCP server in your Claude Code session now (the /mcp command, or restart the session) before driving the vhost checks — this only changed the registration, not any already-running connection." >&2
}

# Composed with run-vm-install.sh's own `cleanup` (trap cleanup EXIT, set
# when it was sourced above) rather than a second `trap ... EXIT` — bash
# only keeps the LAST trap registered for a given signal, so overwriting
# it outright would have silently dropped VM cleanup instead of adding to
# it.
#
# Only restores the chrome-devtools registration when this script is
# exiting WITHOUT having reached "TIER 3 READY" (WIZ_TIER3_READY unset) —
# see this file's own header comment for why an unconditional restore
# here is wrong (it would fire before Part B, run afterward in a
# separate process, ever gets to use the swapped-in flag). Same
# WIZ_TEST_PASSED-style "only skip cleanup on a real success" shape
# run-vm-install.sh's own cleanup() already uses for the VM itself.
tier3_cleanup() {
  if [ "${WIZ_TIER3_READY:-0}" != "1" ]; then
    chrome_mcp_restore
  fi
  cleanup
}
trap tier3_cleanup EXIT

chrome_mcp_swap_in

export WIZ_TEST_KEEP_VM=1
echo "== Running Tier 2 to produce an installed, running, fully-featured test VM ==" >&2
tier2_run_and_install_wizard

# The INSTALLED target (post-reboot) is a different system than the live
# installer ISO ssh_cmd() talks to — this one has root SSH login disabled
# by policy (modules/common.nix's own posture: "root login stays disabled
# either way"), so ssh_cmd() (root@...) can't reach it regardless of any
# key. run-vm-install.sh's SSH-access keystrokes paste this SAME
# $SCRATCH/test_key onto the target's first user (testadmin) specifically
# for this — see that script's own comment on why that's used instead of
# password auth (a first version tried password auth via plink here and
# hit intermittent segfaults running it non-interactively/backgrounded on
# Windows; plain ssh with a key sidesteps that entirely and is the same
# well-proven mechanism ssh_cmd() itself already uses against the live
# ISO).
target_ssh_cmd() {
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=5 -i "$SCRATCH/test_key" -p "$SSH_PORT" testadmin@127.0.0.1 "$@"
}

# Same bounded-retry shape as "Waiting for SSH" above — the reboot into
# the installed system isn't instant, and the immediate post-reboot
# connection attempt in an earlier version of this script raced it
# (failed with "Connection timed out during banner exchange").
echo "== Waiting for the installed system's SSH (as testadmin) to come up after reboot (up to ${BOOT_TIMEOUT_SECS}s) ==" >&2
target_waited=0
until target_ssh_cmd true 2>/dev/null; do
  target_waited=$((target_waited + 5))
  if [ "$target_waited" -ge "$BOOT_TIMEOUT_SECS" ]; then
    echo "TIER 3 FAILED: installed system's SSH (testadmin) never came up within ${BOOT_TIMEOUT_SECS}s after reboot." >&2
    exit 1
  fi
  sleep 5
done
echo "Installed system's SSH is up after ~${target_waited}s." >&2

# name:backend-port, matching modules/traefik.nix's own `backends` map —
# keep in sync with that file if it ever changes. "dashboard" isn't in
# that map (it's traefik.nix's own hardcoded loadBalancer server, port
# 8097) and has no vhost prefix (routed at Host(`${hostName}.${domain}`)
# directly), handled separately below.
SERVICE_BACKENDS=(
  "jellyfin:8096" "plex:32400" "sonarr:8989" "radarr:7878" "jackett:9117"
  "seerr:5055" "qbittorrent:8080" "frigate:8098" "hass:8123" "minio:9000"
  "minio-console:9001" "files:8095" "vaultwarden:8222" "scrutiny:8223"
  "immich:2283" "immich-share:3000" "auth:9091"
)

echo "== Opening one SSH tunnel with a local port-forward per service ==" >&2
TUNNEL_ARGS=()
LOCAL_PORT=18000
declare -A DIRECT_URLS=()
declare -A VHOST_URLS=()

add_tunnel() {
  local name="$1" backend_port="$2" vhost_name="$3"
  TUNNEL_ARGS+=(-L "$LOCAL_PORT:127.0.0.1:$backend_port")
  DIRECT_URLS["$name"]="http://127.0.0.1:$LOCAL_PORT/"
  VHOST_URLS["$name"]="https://${vhost_name}.${TEST_INSTANCE}.${TEST_DOMAIN}:18443/"
  LOCAL_PORT=$((LOCAL_PORT + 1))
}

for entry in "${SERVICE_BACKENDS[@]}"; do
  svc="${entry%%:*}"
  port="${entry##*:}"
  add_tunnel "$svc" "$port" "$svc"
done
add_tunnel "dashboard" 8097 ""
# Dashboard's vhost has no service-name prefix — overwrite the generic
# add_tunnel guess with the real router rule (Host(`${hostName}.${domain}`)).
VHOST_URLS["dashboard"]="https://${TEST_INSTANCE}.${TEST_DOMAIN}:18443/"

TUNNEL_ARGS+=(-L "18443:127.0.0.1:443")

# Same key/user as target_ssh_cmd() above. -f backgrounds it the normal
# OpenSSH way once auth succeeds; no `disown` needed the way a plain
# shell `&` background job would (ssh -f detaches from the controlling
# terminal/job table itself), so it survives this script's own exit —
# the whole point: the tunnel needs to still be up for Part B, run
# interactively afterward.
TUNNEL_LOG="$SCRATCH/tier3-tunnel.log"
ssh -f -N -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o ConnectTimeout=5 -o ExitOnForwardFailure=yes \
  -i "$SCRATCH/test_key" -p "$SSH_PORT" "${TUNNEL_ARGS[@]}" testadmin@127.0.0.1 \
  > "$TUNNEL_LOG" 2>&1
echo "Tunnels up (local ports 18000-$((LOCAL_PORT - 1)), 18443 -> Traefik https)." >&2

echo "== Writing manifest ==" >&2
WIZ_TIER3_MANIFEST="$SCRATCH/tier3-manifest.json"
{
  echo "{"
  echo "  \"vhost_prereqs\": \"Add each vhost hostname below to C:\\\\Windows\\\\System32\\\\drivers\\\\etc\\\\hosts pointing at 127.0.0.1 (one line per name, no wildcard support). This script already re-registered the chrome-devtools MCP server with --accept-insecure-certs, but that only takes effect once this Claude Code session reconnects it (the /mcp command, or a session restart) — do that before navigating to any vhost URL below.\","
  echo "  \"direct\": {"
  first=1
  for svc in "${!DIRECT_URLS[@]}"; do
    [ "$first" = 1 ] || echo ","
    first=0
    printf '    "%s": "%s"' "$svc" "${DIRECT_URLS[$svc]}"
  done
  echo
  echo "  },"
  echo "  \"vhost\": {"
  first=1
  for svc in "${!VHOST_URLS[@]}"; do
    [ "$first" = 1 ] || echo ","
    first=0
    printf '    "%s": "%s"' "$svc" "${VHOST_URLS[$svc]}"
  done
  echo
  echo "  }"
  echo "}"
} > "$WIZ_TIER3_MANIFEST"

WIZ_TIER3_READY=1

echo >&2
echo "TIER 3 (part A) READY: VM running, tunnels up, manifest written." >&2
echo "WIZ_TIER3_MANIFEST=$WIZ_TIER3_MANIFEST" >&2
echo >&2
echo "The chrome-devtools MCP server is still registered with --accept-insecure-certs (reconnect it now — the /mcp command — before driving vhost checks). Once Part B is done, restore it yourself:" >&2
echo "  claude mcp remove chrome-devtools -s local" >&2
echo "  claude mcp add chrome-devtools -s user -- npx chrome-devtools-mcp@latest" >&2
echo "(then reconnect once more)." >&2
cat "$WIZ_TIER3_MANIFEST"
