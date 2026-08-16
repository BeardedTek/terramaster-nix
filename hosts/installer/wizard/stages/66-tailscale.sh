#!/usr/bin/env bash

stage_66_tailscale() {
  [ "$(wiz_get feature_tailscale)" = "true" ] || return 0

  wiz_set have_tailscale "false"

  local choice
  choice=$(wiz_menu "Tailscale" "Tailscale is enabled. Connect this box to your tailnet now?" \
    "authcode" "Enter a reusable auth key (from the Tailscale admin console)" \
    "authlink" "Get a login link (open it in a browser to authenticate this device)" \
    "skip" "Skip — connect later from the dashboard")

  case "$choice" in
    authcode)
      local key
      key=$(wiz_password "Tailscale auth key" "Paste a reusable auth key from https://login.tailscale.com/admin/settings/keys.")
      if [ -n "$key" ]; then
        wiz_set tailscale_authkey "$key"
        wiz_set have_tailscale "authkey"
      fi
      unset key
      ;;
    authlink)
      _wiz_tailscale_live_login
      ;;
    skip) ;;
  esac
}

# Live tailscaled runs on THIS installer session (see
# hosts/installer/configuration.nix's services.tailscale.enable, added
# just for this) to get a real, fresh login URL — same interactive flow
# modules/dashboard-tailscale.nix's loginApplyScript drives post-install,
# just synchronous here since whiptail dialogs block naturally (no JS
# polling loop needed, unlike that module's own frontend). On success,
# 90-install.sh persists THIS session's own now-authenticated
# /var/lib/tailscale state onto the target instead of an authkey file —
# there's no reusable key in this flow, only the resulting node identity.
#
# Under Tier 1 (test/lib/mock-wiz.sh), wiz_menu is fully mocked — this
# function only ever runs if a fixture's own scripted answer for the
# "Tailscale" menu is "authlink", which the real fixture never picks, so
# this live-network code path needs no special-casing to stay safe there.
_wiz_tailscale_live_login() {
  systemctl start tailscaled 2>/dev/null
  : > /tmp/wiz-tailscale-login.log
  tailscale up >> /tmp/wiz-tailscale-login.log 2>&1 &

  local url="" waited=0
  while [ -z "$url" ] && [ "$waited" -lt 30 ]; do
    url=$(grep -oE 'https://login\.tailscale\.com/a/[A-Za-z0-9]+' /tmp/wiz-tailscale-login.log | head -n1 || true)
    [ -n "$url" ] || { sleep 1; waited=$((waited + 1)); }
  done
  if [ -z "$url" ]; then
    wiz_msgbox "No login link" "Tailscale didn't print a login link within 30s (no network, or tailscaled unreachable). Skipping — connect later from the dashboard."
    return
  fi

  wiz_msgbox "Tailscale login" "Open this link in a browser on any device and log in:

$url

Press OK once you're done."

  while true; do
    [ "$(tailscale status --json 2>/dev/null | jq -r '.BackendState // empty')" = "Running" ] && break
    wiz_yesno "Still waiting" "Not logged in yet. Keep waiting?" || {
      wiz_msgbox "Skipped" "Giving up on the login link — connect later from the dashboard."
      return
    }
    sleep 2
  done

  wiz_msgbox "Connected" "This box is now connected to your tailnet."
  wiz_set have_tailscale "live"
}
