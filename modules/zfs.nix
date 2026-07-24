{ ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd.supportedFilesystems = [ "zfs" ];

  services.zfs.autoScrub.enable = true;

  boot.zfs.forceImportRoot = false;

  boot.kernelParams = [ "zfs.zfs_arc_max=8589934592" ]; # 8GiB
}
