#!/usr/bin/env bash

stage_40_storage_existing() {
  local importable
  importable=$(pool_existing_importable)

  local pool
  if [ -n "$importable" ]; then
    local menu_items=()
    local p
    while IFS= read -r p; do
      [ -n "$p" ] && menu_items+=("$p" "")
    done <<< "$importable"
    menu_items+=("__other__" "Type a different pool name")
    pool=$(wiz_menu "Existing pool" "zpool import sees these pools available to import:" "${menu_items[@]}")
    if [ "$pool" = "__other__" ]; then
      pool=$(wiz_input "Pool name" "Name of the existing pool to adopt:")
    fi
  else
    pool=$(wiz_input "Pool name" \
      "zpool import didn't list any importable pools (already imported, or none present). Type the pool name to adopt:" \
      "rust")
  fi
  wiz_set pool_name "$pool"

  wiz_yesno "Adopt $pool?" "About to run, right now (this is metadata-only — never touches file data):

  zgenhostid -f $(wiz_get hostid)
  zpool import -N -f $pool
  zfs set mountpoint=legacy  <- on every existing dataset in $pool
  zfs create <pool>/nix and <pool>/persist if they don't already exist

Continue?" || wiz_abort "Declined adopting pool $pool"

  local datasets
  datasets=$(pool_existing_adopt "$pool" "$(wiz_get hostid)")
  wiz_set existing_datasets "$datasets"

  local menu_items=()
  local d
  while IFS= read -r d; do
    [ -n "$d" ] && menu_items+=("$d" "")
  done <<< "$datasets"

  local role
  for role in home media data; do
    local picked
    picked=$(wiz_menu "Map \"$role\"" \
      "Which existing dataset in $pool should be used for $role (mounted at /$role or /$pool/$role)?" \
      "${menu_items[@]}")
    wiz_set "role_$role" "$picked"
  done

  local boot_disk
  boot_disk=$(wiz_pick_boot_disk)
  wiz_set boot_disk "$boot_disk"

  local disko_out
  disko_out="$WIZ_REPO_WORKDIR/hosts/$(wiz_get manufacturer)/$(wiz_get instance)/disko.nix"
  mkdir -p "$(dirname "$disko_out")"
  pool_new_generate_disko_boot_only "$disko_out" "$boot_disk"
  wiz_set disko_file "$disko_out"
}
