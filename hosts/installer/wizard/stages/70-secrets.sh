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

  wiz_set use_password_auth "false"

  local pubkey=""
  if [ -n "$(wiz_get secrets_usb)" ] && [ -f "$(wiz_get secrets_usb)/authorized_keys" ]; then
    pubkey=$(cat "$(wiz_get secrets_usb)/authorized_keys")
  fi

  # No USB key found — ask how to get one, rather than demanding it be
  # pasted (unrealistic from a TUI on a box that may not even be online
  # yet at this point, if it's being typed by hand off a phone screen).
  if [ -z "$pubkey" ]; then
    local first_user
    first_user=$(wiz_get user_list | head -n1)

    while [ -z "$pubkey" ]; do
      local choice
      choice=$(wiz_menu "SSH access for $first_user" \
        "No SSH key found on a NAS-SECRETS USB drive. How should $first_user log in over SSH?" \
        "github" "Fetch public key(s) from a GitHub username" \
        "paste" "Paste an SSH public key directly" \
        "password" "Skip — use a password instead (less secure)")

      case "$choice" in
        github)
          local gh_user
          gh_user=$(wiz_input "GitHub username" "Fetch public key(s) from https://github.com/<username>.keys. Requires network access.")
          [ -z "$gh_user" ] && continue
          local fetched
          fetched=$(curl -fsSL "https://github.com/${gh_user}.keys" 2>/dev/null || true)
          if [ -z "$fetched" ]; then
            wiz_msgbox "No keys found" "Couldn't fetch any keys for \"$gh_user\" (no network, wrong username, or that account has no public keys attached). Try again."
            continue
          fi
          pubkey="$fetched"
          wiz_msgbox "Key(s) fetched" "$(printf '%s' "$fetched" | wc -l) public key(s) fetched from github.com/$gh_user and will be installed for $first_user."
          ;;
        paste)
          pubkey=$(wiz_input "SSH public key" "Paste the SSH public key for $first_user.")
          [ -z "$pubkey" ] && wiz_msgbox "Empty" "That was empty — try again, or pick a different option."
          ;;
        password)
          wiz_yesno "Use password login?" "$first_user will log in over SSH with the password set earlier instead of a key. This is less secure than key-only auth (the default for every other instance this flake provisions) — recommended only when no key is available right now. Continue?" \
            && { wiz_set use_password_auth "true"; pubkey="-"; } \
            || true
          ;;
      esac
    done
  fi

  # "-" is the password-only sentinel from above — never written as key
  # material, just breaks the outer while-loop cleanly.
  if [ "$pubkey" = "-" ]; then
    pubkey=""
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

  # LLDAP's bootstrap admin password — the one new SSO-related secret a
  # human actually needs to know, since it's used to log into LLDAP's own
  # admin UI right after install (see 90-install.sh's final message).
  # Every other new secret (Authelia's crypto secrets, the per-service
  # LDAP bind-account passwords) is a machine-to-machine credential,
  # generated and written directly by 90-install.sh with no prompt needed.
  if [ "$(wiz_get feature_sso)" = "true" ]; then
    local ldap_pw ldap_pw2
    while true; do
      ldap_pw=$(wiz_password "LLDAP admin password" "Set the LLDAP directory's bootstrap admin password — you'll use this to log into LLDAP's own admin UI after install and set an initial password for each user.")
      ldap_pw2=$(wiz_password "LLDAP admin password" "Confirm:")
      [ "$ldap_pw" = "$ldap_pw2" ] && [ -n "$ldap_pw" ] && break
      wiz_msgbox "Mismatch" "Passwords didn't match or were empty — try again."
    done
    wiz_set ldap_admin_password "$ldap_pw"
    unset ldap_pw ldap_pw2
  fi
}
