{ lib, ... }:

let
  zfsPool = import ../../../lib/zfs-pool.nix {
    inherit lib;
    poolName = "rust";
    raidLevel = "raidz1";
    disks = [
      "/dev/disk/by-id/CHANGEME-hdd-bay-1"
      "/dev/disk/by-id/CHANGEME-hdd-bay-2"
      "/dev/disk/by-id/CHANGEME-hdd-bay-3"
      "/dev/disk/by-id/CHANGEME-hdd-bay-4"
    ];
    datasets = [
      { name = "nix"; mountpoint = "/nix"; }
      { name = "persist"; mountpoint = "/persist"; }
      { name = "home"; mountpoint = "/home"; }
      { name = "media"; mountpoint = "/rust/media"; }
      { name = "data"; mountpoint = "/rust/data"; }
      { name = "minio"; mountpoint = "/rust/minio"; }
    ];
  };
in
lib.mkMerge [
  zfsPool
  {
    disko.devices.disk.usb = {
      device = "/dev/disk/by-id/CHANGEME-usb-boot-drive";
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
