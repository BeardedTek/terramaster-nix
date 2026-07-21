{ ... }:

{
  # Generic ZFS knobs. Host-specific bits (networking.hostId, the actual
  # fileSystems entries for the `rust` pool's datasets) live in
  # hosts/young/configuration.nix since a hostId must never be shared
  # across machines.
  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd.supportedFilesystems = [ "zfs" ];

  services.zfs.autoScrub.enable = true;

  # Root isn't on ZFS (it's tmpfs), so this doesn't govern anything for us
  # in practice — set explicitly to the safer, soon-to-be-default value
  # rather than leaving it on the (about-to-change) implicit default.
  boot.zfs.forceImportRoot = false;

  # Box has 16GB DDR4-3200 total. ZFS's default ARC sizing (up to ~50% of
  # RAM) would leave only ~8GB for Jellyfin transcoding + the *arr stack +
  # system. Cap explicitly; revisit with `arc_summary` if it's too tight
  # or too loose in practice.
  boot.kernelParams = [ "zfs.zfs_arc_max=8589934592" ]; # 8GiB
}
