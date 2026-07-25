#!/usr/bin/env bash

stage_30_instance() {
  local manufacturer instance hostname hostid

  manufacturer=$(wiz_input "Manufacturer" \
    "Lowercase, no spaces — becomes the first path segment of hosts/<manufacturer>/<instance>/.

Existing directories in this repo: $(find "$WIZ_REPO_WORKDIR/hosts" -mindepth 1 -maxdepth 1 -type d -printf '%f ' 2>/dev/null)" \
    "terramaster")
  wiz_set manufacturer "$manufacturer"

  instance=$(wiz_input "Instance name" \
    "Identifies THIS physical box — lowercase, no spaces. Becomes hosts/${manufacturer}/<instance>/. Doesn't have to be a model number; young's own directory is just named \"young\".

Existing instances under ${manufacturer}/: $(find "$WIZ_REPO_WORKDIR/hosts/$manufacturer" -mindepth 1 -maxdepth 1 -type d -printf '%f ' 2>/dev/null)")
  if [ -z "$instance" ]; then
    wiz_die "Instance name can't be empty."
  fi
  if [ -e "$WIZ_REPO_WORKDIR/hosts/$manufacturer/$instance" ]; then
    wiz_yesno "Directory already exists" "hosts/${manufacturer}/${instance}/ already exists in this checkout. Continuing will overwrite its disko.nix and configuration.nix.

Continue?" || wiz_abort "Instance directory already exists: $manufacturer/$instance"
  fi
  wiz_set instance "$instance"

  hostname=$(wiz_input "Hostname" \
    "networking.hostName — also drives every Traefik domain and the Samba server name (see docs/ARCHITECTURE.md's variables.nix section)." \
    "$instance")
  wiz_set hostname "$hostname"

  hostid=$(head -c8 /etc/machine-id 2>/dev/null || true)
  if [ -z "$hostid" ]; then
    hostid=$(tr -dc 'a-f0-9' < /dev/urandom | head -c8)
  fi
  hostid=$(wiz_input "ZFS hostid" \
    "8 hex digits, required by ZFS. Auto-generated below — leave as-is unless you have a specific reason to change it." \
    "$hostid")
  if ! [[ "$hostid" =~ ^[0-9a-f]{8}$ ]]; then
    wiz_die "hostid must be exactly 8 lowercase hex digits, got: $hostid"
  fi
  wiz_set hostid "$hostid"
}
