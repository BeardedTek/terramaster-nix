#!/usr/bin/env bash
# Path A: adopt an existing, already-populated ZFS pool. Every function
# here is a thin wrapper around real zpool/zfs commands (or, under
# WIZ_DRY_RUN=1, prints what it would run instead) so the flow in
# stages/40-storage-existing.sh can be exercised without real disks.

# Lists pools zpool can see to import but hasn't yet (one per line).
pool_existing_importable() {
  if [ "${WIZ_DRY_RUN:-0}" = "1" ]; then
    printf '%s\n' "${WIZ_DRY_RUN_POOLS:-rust}"
    return 0
  fi
  zpool import 2>/dev/null | awk '/^   pool:/ {print $2}'
}

# Stamps this session's hostid to match what the target config will use,
# then imports without mounting (-N) so we control mounting explicitly
# afterward, matching docs/DEPLOYMENT.md step 3's reasoning: the pool was
# last imported under a different host's hostid, and importing under the
# wrong one now means every later boot mismatches again.
pool_existing_import() {
  local pool="$1" host_id="$2"
  if [ "${WIZ_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] zgenhostid -f $host_id; zpool import -N -f $pool"
    return 0
  fi
  zgenhostid -f "$host_id"
  zpool import -N -f "$pool"
}

# Every dataset that exists right now, one per line — not a hardcoded
# list, since a different box's pool has a different history than
# young's. Includes the pool's own top-level dataset.
pool_existing_list_datasets() {
  local pool="$1"
  if [ "${WIZ_DRY_RUN:-0}" = "1" ]; then
    printf '%s\n' "${WIZ_DRY_RUN_DATASETS:-$pool
$pool/home
$pool/media
$pool/data}"
    return 0
  fi
  zfs list -r -H -o name "$pool"
}

# Property-only change, confirmed safe (docs/ARCHITECTURE.md's "every rust
# dataset must be mountpoint=legacy" section) — never touches data. Every
# dataset returned by pool_existing_list_datasets needs this, not just the
# ones this flake newly cares about, or ZFS's own auto-mount can still
# race NixOS's systemd mount units for any of them.
pool_existing_fix_mountpoint() {
  local dataset="$1"
  if [ "${WIZ_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] zfs set mountpoint=legacy $dataset"
    return 0
  fi
  zfs set mountpoint=legacy "$dataset"
}

pool_existing_dataset_exists() {
  local dataset="$1"
  if [ "${WIZ_DRY_RUN:-0}" = "1" ]; then
    local line
    while IFS= read -r line; do
      [ "$line" = "$dataset" ] && return 0
    done <<< "${WIZ_DRY_RUN_DATASETS:-}"
    return 1
  fi
  zfs list -H -o name "$dataset" >/dev/null 2>&1
}

# Creates a dataset this flake needs (nix, persist) that a pool from
# before this flake existed obviously wouldn't already have. Already
# legacy at creation, so no separate fix-mountpoint call is required
# for these two, though running one anyway is harmless.
pool_existing_create_dataset() {
  local dataset="$1"
  if [ "${WIZ_DRY_RUN:-0}" = "1" ]; then
    echo "[dry-run] zfs create -o mountpoint=legacy $dataset"
    return 0
  fi
  zfs create -o mountpoint=legacy "$dataset"
}

# Runs the full adoption sequence: import, enumerate, fix every existing
# dataset's mountpoint, then create nix/persist if they're not already
# there. Prints the final dataset list (post-creation) on stdout, one per
# line, for the caller to build role-mapping prompts from.
pool_existing_adopt() {
  local pool="$1" host_id="$2"
  pool_existing_import "$pool" "$host_id"

  local ds
  while IFS= read -r ds; do
    [ -n "$ds" ] && pool_existing_fix_mountpoint "$ds"
  done < <(pool_existing_list_datasets "$pool")

  for extra in nix persist; do
    if ! pool_existing_dataset_exists "$pool/$extra"; then
      pool_existing_create_dataset "$pool/$extra"
    fi
  done

  pool_existing_list_datasets "$pool"
}
