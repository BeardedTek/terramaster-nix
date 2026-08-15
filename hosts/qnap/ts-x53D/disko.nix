{ lib, ... }:

let
  zfsPool = import ../../../lib/zfs-pool.nix {
    inherit lib;
    poolName = "rust";
    raidLevel = "mirror";
    disks = [
      "/dev/disk/by-id/ata-ST4000VN008-2DR166_ZGY9B8D1"
      "/dev/disk/by-id/ata-ST4000VN008-2DR166_ZGY9B8GG"
    ];
    datasets = [
      { name = "nix"; mountpoint = "/nix"; }
      { name = "persist"; mountpoint = "/persist"; }
      { name = "home"; mountpoint = "/home"; }
      { name = "media"; mountpoint = "/rust/media"; }
      { name = "data"; mountpoint = "/rust/data"; }
    ];
  };
in
lib.mkMerge [
  zfsPool
  {
    disko.devices.disk.usb = {
      device = "/dev/disk/by-id/mmc-004GA0_0xddd6973b";
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
