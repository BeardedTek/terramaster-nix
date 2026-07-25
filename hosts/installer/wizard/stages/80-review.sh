#!/usr/bin/env bash

stage_80_review() {
  local storage_summary
  if [ "$(wiz_get storage_path)" = "existing" ]; then
    storage_summary="Adopt existing pool \"$(wiz_get pool_name)\" (non-destructive — dataset properties only)
  home -> $(wiz_get role_home)
  media -> $(wiz_get role_media)
  data -> $(wiz_get role_data)"
  else
    storage_summary="Create NEW pool \"$(wiz_get pool_name)\" ($(wiz_get raid_level))
  boot drive: $(wiz_get boot_disk)
  pool disks:
$(wiz_get pool_disks | sed 's/^/    /')
  THIS WILL DESTROY EVERYTHING CURRENTLY ON THOSE DISKS"
  fi

  local ssh_summary
  if [ "$(wiz_get use_password_auth)" = "true" ]; then
    ssh_summary="password login (no SSH key set — less secure than key-only)"
  else
    ssh_summary="SSH key only"
  fi

  wiz_msgbox "Review" "manufacturer/instance: $(wiz_get manufacturer)/$(wiz_get instance)
hostname: $(wiz_get hostname)
LAN interface: $(wiz_get lan_if)
repo source: $(wiz_get repo_source)

STORAGE:
$storage_summary

USERS:
$(wiz_get user_list | sed 's/^/  /')

SSH ACCESS: $ssh_summary

Next screen asks for final confirmation."

  if [ "$(wiz_get storage_path)" = "new" ]; then
    wiz_type_to_confirm \
      "About to run disko against $(wiz_get pool_disks | tr '\n' ' ') and $(wiz_get boot_disk).

THIS PERMANENTLY DESTROYS ALL DATA on those disks. There is no undo." \
      "DESTROY" \
      || wiz_abort "Destructive confirmation not typed correctly — aborting before touching any disk."
  else
    wiz_yesno "Proceed?" "Ready to write config and install. Proceed?" \
      || wiz_abort "Declined final confirmation."
  fi
}
