#!/usr/bin/env bash

# Discovery and disko.nix generation only — writes a file, runs nothing
# destructive. The actual disko invocation happens in 90-install.sh, after
# 80-review.sh's typed DESTROY confirmation.
stage_40_storage_new() {
  local disks=()
  local d
  while IFS= read -r d; do
    [ -n "$d" ] && disks+=("$d")
  done < <(pool_new_list_disks)

  if [ "${#disks[@]}" -lt 2 ]; then
    wiz_die "Only found ${#disks[@]} whole disk(s) under /dev/disk/by-id/ — need at least one for the boot drive and one for the pool."
  fi

  local boot_disk
  boot_disk=$(wiz_pick_boot_disk)
  wiz_set boot_disk "$boot_disk"

  local pool_menu=()
  local dirty_disks=()
  for d in "${disks[@]}"; do
    [ "$d" = "$boot_disk" ] && continue
    local sig size_h
    sig=$(pool_new_disk_signature "$d")
    size_h=$(pool_new_human_size "$(pool_new_disk_size_bytes "$d")")
    if [ -n "$sig" ]; then
      dirty_disks+=("$d")
      pool_menu+=("$d" "$size_h — HAS EXISTING DATA, will be excluded unless confirmed" "OFF")
    else
      pool_menu+=("$d" "$size_h — blank" "ON")
    fi
  done

  if [ "${#pool_menu[@]}" -eq 0 ]; then
    wiz_die "No disks left for the pool after excluding the boot drive ($boot_disk)."
  fi

  local selected
  selected=$(wiz_checklist "Pool disks" "Select every disk that should join the new pool. Disks marked \"HAS EXISTING DATA\" are unchecked by default." "${pool_menu[@]}")
  # whiptail prints tags space-separated, double-quoted — by-id device
  # names never contain spaces, so stripping quotes and word-splitting is
  # safe here and avoids eval.
  local -a pool_disks=()
  read -ra pool_disks <<< "${selected//\"/}"

  if [ "${#pool_disks[@]}" -lt 1 ]; then
    wiz_die "No disks selected for the pool."
  fi

  for d in "${pool_disks[@]}"; do
    for dirty in "${dirty_disks[@]:-}"; do
      if [ "$d" = "$dirty" ]; then
        wiz_yesno "Confirm: $d has existing data" "$d was flagged as having an existing filesystem/RAID/ZFS signature on it. Selecting it means IT WILL BE WIPED along with everything else in this pool.

Are you certain you want to include $d?" || wiz_die "Aborted: $d has existing data and wasn't confirmed."
      fi
    done
  done

  wiz_set pool_disks "$(printf '%s\n' "${pool_disks[@]}")"

  local raid
  raid=$(wiz_menu "RAID level" "Redundancy across the ${#pool_disks[@]} selected disk(s):" \
    "raidz1" "Single-parity, matches young's own pool (needs 3+ disks)" \
    "mirror" "Mirror (needs exactly 2 disks per mirror group)" \
    "raidz2" "Double-parity (needs 4+ disks)" \
    "" "Stripe — no redundancy at all, not recommended")
  wiz_set raid_level "$raid"

  local pool
  pool=$(wiz_input "Pool name" \
    "modules/media-stack.nix, samba.nix, and nfs.nix hardcode /rust/media and /rust/data — keep this as \"rust\" unless you're also updating those modules." \
    "rust")
  wiz_set pool_name "$pool"

  local disko_out
  disko_out="$WIZ_REPO_WORKDIR/hosts/$(wiz_get manufacturer)/$(wiz_get instance)/disko.nix"
  mkdir -p "$(dirname "$disko_out")"
  pool_new_generate_disko "$disko_out" "$pool" "$raid" "$boot_disk" "${pool_disks[@]}"
  wiz_set disko_file "$disko_out"

  whiptail --backtitle "$WHIPTAIL_BACKTITLE" --title "Generated disko.nix" \
    --textbox "$disko_out" 30 90
}
