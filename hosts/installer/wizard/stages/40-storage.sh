#!/usr/bin/env bash

stage_40_storage() {
  local choice
  choice=$(wiz_menu "Storage" "How should this NAS's ZFS pool be set up?" \
    "existing" "Adopt an existing, already-populated pool (non-destructive)" \
    "new" "Create a new pool on blank disks (DESTRUCTIVE)")
  wiz_set storage_path "$choice"

  case "$choice" in
    existing) stage_40_storage_existing ;;
    new) stage_40_storage_new ;;
  esac
}
