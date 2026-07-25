#!/usr/bin/env bash
# Path B: create a brand-new ZFS pool on genuinely blank disks. Same
# dry-run convention as lib/pool-existing.sh (WIZ_DRY_RUN=1 plus
# WIZ_DRY_RUN_* fixtures) so the discovery/generation logic can be
# exercised without real disks.

# Whole-disk /dev/disk/by-id/* entries, one per line — excludes the
# "-partN" links udev creates alongside each disk's own by-id entry (the
# same style of stable path hosts/terramaster/*/disko.nix already uses for
# the USB boot drive).
pool_new_list_disks() {
  if [ "${WIZ_DRY_RUN:-0}" = "1" ]; then
    printf '%s\n' "${WIZ_DRY_RUN_DISKS:-}"
    return 0
  fi
  find /dev/disk/by-id/ -maxdepth 1 -mindepth 1 ! -name '*-part[0-9]*' -printf '%f\n' 2>/dev/null | sort
}

pool_new_disk_size_bytes() {
  local dev="$1"
  if [ "${WIZ_DRY_RUN:-0}" = "1" ]; then
    printf '%s' "${WIZ_DRY_RUN_SIZE_BYTES:-6001175126016}"
    return 0
  fi
  blockdev --getsize64 "/dev/disk/by-id/$dev" 2>/dev/null || echo 0
}

# Empty stdout = no signature found (safe to preselect). Non-empty = a
# filesystem/RAID/ZFS label was found and this disk must NOT be
# preselected in the wizard's checklist.
pool_new_disk_signature() {
  local dev="$1"
  if [ "${WIZ_DRY_RUN:-0}" = "1" ]; then
    case ",${WIZ_DRY_RUN_DIRTY_DISKS:-}," in
      *",$dev,"*) echo "dry-run-fixture-signature" ;;
    esac
    return 0
  fi
  wipefs -n "/dev/disk/by-id/$dev" 2>/dev/null | tail -n +2
}

pool_new_human_size() {
  local bytes="$1"
  awk -v b="$bytes" 'BEGIN {
    split("B KB MB GB TB PB", units, " ");
    u = 1;
    while (b >= 1024 && u < 6) { b /= 1024; u++ }
    printf "%.1f %s", b, units[u]
  }'
}

# Writes a disko.nix using lib/zfs-pool.nix, same shape as
# hosts/terramaster/f4-245/disko.nix's template but with real values.
# $3 (bootDisk) and $4 (poolDisks, newline-separated) are by-id basenames,
# not full paths — the full "/dev/disk/by-id/" prefix is added here so
# every caller works with the same short names pool_new_list_disks prints.
pool_new_generate_disko() {
  local out_file="$1" pool_name="$2" raid_level="$3" boot_disk="$4"
  shift 4
  local pool_disks=("$@")

  local disks_nix=""
  local d
  for d in "${pool_disks[@]}"; do
    disks_nix+="      \"/dev/disk/by-id/${d}\"
"
  done

  cat > "$out_file" <<EOF
{ lib, ... }:

let
  zfsPool = import ../../../lib/zfs-pool.nix {
    inherit lib;
    poolName = "${pool_name}";
    raidLevel = "${raid_level}";
    disks = [
${disks_nix}    ];
    datasets = [
      { name = "nix"; mountpoint = "/nix"; }
      { name = "persist"; mountpoint = "/persist"; }
      { name = "home"; mountpoint = "/home"; }
      { name = "media"; mountpoint = "/${pool_name}/media"; }
      { name = "data"; mountpoint = "/${pool_name}/data"; }
    ];
  };
in
lib.mkMerge [
  zfsPool
  {
    disko.devices.disk.usb = {
      device = "/dev/disk/by-id/${boot_disk}";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
        };
      };
    };
  }
]
EOF
}

# For Path A (existing pool): disko still owns the boot drive, same as
# hosts/terramaster/young/disko.nix — just no zpool block, since an
# adopted pool is never disko-managed.
pool_new_generate_disko_boot_only() {
  local out_file="$1" boot_disk="$2"
  cat > "$out_file" <<EOF
{
  disko.devices.disk.usb = {
    device = "/dev/disk/by-id/${boot_disk}";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
      };
    };
  };
}
EOF
}

# Shared by both storage paths — every install needs exactly one boot
# drive picked, regardless of how the data pool itself gets set up.
wiz_pick_boot_disk() {
  local disks=()
  local d
  while IFS= read -r d; do
    [ -n "$d" ] && disks+=("$d")
  done < <(pool_new_list_disks)

  if [ "${#disks[@]}" -eq 0 ]; then
    wiz_die "No disks found under /dev/disk/by-id/."
  fi

  local menu=()
  for d in "${disks[@]}"; do
    menu+=("$d" "$(pool_new_human_size "$(pool_new_disk_size_bytes "$d")")")
  done
  wiz_menu "Boot drive" "Which disk should hold the boot/system partition?" "${menu[@]}"
}

# Actually formats/creates/mounts everything disko.nix declares. Only
# call this after the wizard's typed DESTROY confirmation — everything
# up to here (discovery, signature scan, file generation) is read-only.
pool_new_run_disko() {
  local flake_path="$1" attr="$2"
  if [ "${WIZ_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] disko --mode destroy,format,mount --flake ${flake_path}#${attr}"
    return 0
  fi
  disko --mode destroy,format,mount --flake "${flake_path}#${attr}"
}
