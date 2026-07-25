#!/usr/bin/env bash

# Looks for a conventionally-named secrets USB (LABEL=NAS-SECRETS) before
# falling back to interactive prompts. Its own flat layout — not
# docs/DEPLOYMENT.md's secrets/extra-files/ tree, which is nested under a
# specific hardcoded username (home/beardedtek/.ssh/...) that doesn't
# generalize here, since the wizard's admin username is chosen at
# runtime:
#   authorized_keys        -> first user's SSH key
#   etc/nebula/config.yaml -> Nebula config (+ certs alongside it)
#   etc/traefik/traefik.env
# Nebula/Traefik secrets are optional — those services just won't work
# until configured post-install, same as leaving CHANGEME placeholders
# unfilled today.
stage_70_secrets() {
  local usb_mount="/mnt/secrets-usb"
  local usb_dev
  usb_dev=$(blkid -L NAS-SECRETS 2>/dev/null || true)

  if [ -n "$usb_dev" ]; then
    mkdir -p "$usb_mount"
    if mount -o ro "$usb_dev" "$usb_mount" 2>/dev/null; then
      wiz_set secrets_usb "$usb_mount"
      wiz_msgbox "Secrets USB found" "Found a NAS-SECRETS labeled drive, mounted read-only at $usb_mount. authorized_keys and etc/ from it will be copied in during install."
    fi
  fi

  local pubkey=""
  if [ -n "$(wiz_get secrets_usb)" ] && [ -f "$(wiz_get secrets_usb)/authorized_keys" ]; then
    pubkey=$(cat "$(wiz_get secrets_usb)/authorized_keys")
  fi
  if [ -z "$pubkey" ]; then
    pubkey=$(wiz_input "SSH public key" \
      "Paste the SSH public key for the first admin user ($(wiz_get user_list | head -n1)). This is what you'll actually log in with — required.")
  fi
  if [ -z "$pubkey" ]; then
    wiz_die "An SSH public key is required (there's no password-based SSH login in this config)."
  fi
  wiz_set ssh_pubkey "$pubkey"

  if [ -n "$(wiz_get secrets_usb)" ] && [ -f "$(wiz_get secrets_usb)/etc/nebula/config.yaml" ]; then
    wiz_set have_nebula "true"
  elif wiz_yesno "Nebula" "Configure Nebula mesh VPN now? You'll need its config.yaml + certs pasted in (skip to configure it manually later — see docs/DEPLOYMENT.md)."; then
    wiz_msgbox "Not yet supported here" "Pasting a full Nebula config through this wizard isn't implemented — skipping. Copy secrets/extra-files/persist/etc/nebula/ in manually after first boot, or re-run with a NAS-SECRETS USB attached."
    wiz_set have_nebula "false"
  else
    wiz_set have_nebula "false"
  fi

  if [ -n "$(wiz_get secrets_usb)" ] && [ -f "$(wiz_get secrets_usb)/etc/traefik/traefik.env" ]; then
    wiz_set have_traefik "true"
  else
    wiz_set have_traefik "false"
  fi
}
