#!/usr/bin/env bash

stage_90_install() {
  local manufacturer instance host_dir
  manufacturer=$(wiz_get manufacturer)
  instance=$(wiz_get instance)
  host_dir="$WIZ_REPO_WORKDIR/hosts/$manufacturer/$instance"
  mkdir -p "$host_dir"

  wiz_msgbox "Writing config" "Generating variables.nix, configuration.nix, and secrets into $WIZ_REPO_WORKDIR now."

  gen_variables_nix > "$WIZ_REPO_WORKDIR/variables.nix"
  if [ "$(wiz_get storage_path)" = "existing" ]; then
    gen_configuration_nix_existing > "$host_dir/configuration.nix"
  else
    gen_configuration_nix_new > "$host_dir/configuration.nix"
  fi
  mkdir -p "$WIZ_REPO_WORKDIR/secrets"
  gen_initial_passwords_env > "$WIZ_REPO_WORKDIR/secrets/initial-passwords.env"
  chmod 600 "$WIZ_REPO_WORKDIR/secrets/initial-passwords.env"

  # disko.nix was already written by the storage stage (40-storage-existing.sh
  # or 40-storage-new.sh) — it's the one file generated before this point,
  # since 40-storage-new.sh needs to show it for review before the
  # destructive confirmation.

  set -a
  # shellcheck disable=SC1091
  source "$WIZ_REPO_WORKDIR/secrets/initial-passwords.env"
  set +a
  export NIX_CONFIG="pure-eval = false"

  local flake_attr
  flake_attr="$WIZ_REPO_WORKDIR#$(wiz_get hostname)"

  if [ "$(wiz_get storage_path)" = "new" ]; then
    wiz_msgbox "Running disko" "About to format and mount every disk selected earlier. This is the point of no return."
    # Stamp the live session's hostid to match the target BEFORE disko
    # creates the pool — otherwise `zpool create` stamps it with this
    # live ISO's own hostid (hardcoded "00000000"), and the target
    # system's first real boot fails to auto-import it (hostid
    # mismatch, same class of problem docs/DEPLOYMENT.md step 3 already
    # solves for the existing-pool path — confirmed the hard way that
    # the new-pool path needed the exact same fix, just applied earlier,
    # before creation instead of before import).
    wiz_set_hostid "$(wiz_get hostid)"
    pool_new_run_disko "$WIZ_REPO_WORKDIR" "$(wiz_get hostname)"
  else
    # Boot drive only — disko doesn't know about the adopted pool.
    disko --mode destroy,format,mount --flake "$flake_attr"

    local pool home media data
    pool=$(wiz_get pool_name)
    home=$(wiz_get role_home)
    media=$(wiz_get role_media)
    data=$(wiz_get role_data)

    mkdir -p "/mnt/nix" "/mnt/persist" "/mnt/home" "/mnt/$pool"
    mount -t zfs "$pool/nix" /mnt/nix
    mount -t zfs "$pool/persist" /mnt/persist
    mount -t zfs "$home" /mnt/home
    mount -t zfs "$pool" "/mnt/$pool"
    mkdir -p "/mnt/$pool/media" "/mnt/$pool/data"
    mount -t zfs "$media" "/mnt/$pool/media"
    mount -t zfs "$data" "/mnt/$pool/data"
  fi

  local first_user
  first_user=$(wiz_get user_list | head -n1)
  if [ -n "$(wiz_get ssh_pubkey)" ]; then
    mkdir -p "/mnt/home/$first_user/.ssh"
    wiz_get ssh_pubkey > "/mnt/home/$first_user/.ssh/authorized_keys"
    chmod 700 "/mnt/home/$first_user/.ssh"
    chmod 600 "/mnt/home/$first_user/.ssh/authorized_keys"
  fi

  local secrets_usb
  secrets_usb=$(wiz_get secrets_usb)
  if [ -n "$secrets_usb" ] && [ -d "$secrets_usb/etc" ]; then
    mkdir -p /mnt/etc
    cp -r "$secrets_usb/etc/." /mnt/etc/
  fi

  wiz_msgbox "Installing NixOS" "Running nixos-install now — this can take a while (downloading/building packages). The console will show progress."

  # --impure: confirmed the hard way that nixos-install's own internal
  # nix invocation doesn't pick up NIX_CONFIG=pure-eval=false from this
  # shell's environment (unlike plain `nix build`) — modules/users.nix's
  # builtins.getEnv calls need real impure evaluation, not just the env
  # vars being exported.
  nixos-install --root /mnt --flake "$flake_attr" --no-root-password --impure

  mkdir -p /mnt/persist/nixos-installer-output
  cp "$WIZ_REPO_WORKDIR/variables.nix" /mnt/persist/nixos-installer-output/
  cp -r "$host_dir" "/mnt/persist/nixos-installer-output/$instance"
  wiz_msgbox "Done" "Install complete.

Generated config was left at /persist/nixos-installer-output/ on the new system — retrieve it after reboot and commit it into your real git checkout:
  variables.nix
  ${instance}/configuration.nix
  ${instance}/disko.nix

secrets/initial-passwords.env was NOT copied there (it only ever mattered for this install) — recreate it in your own checkout from secrets/initial-passwords.env.example if you'll be rebuilding this box from your workstation later."

  if wiz_yesno "Reboot now?" "Unmount and reboot into the new system?"; then
    # `umount -R /mnt` alone isn't reliable here — confirmed the hard way
    # that it fails with "not mounted" when /mnt itself was never a
    # mountpoint (only its children are, e.g. /mnt/nix, /mnt/persist,
    # /mnt/boot from disko), leaving everything still mounted. Enumerate
    # every actual mount under /mnt and unmount deepest-first instead.
    local mnt
    for mnt in $(findmnt -R -o TARGET -n /mnt 2>/dev/null | sort -r); do
      umount "$mnt" 2>/dev/null || umount -l "$mnt" 2>/dev/null
    done
    zpool export "$(wiz_get pool_name)" 2>/dev/null
    reboot
  fi
}
