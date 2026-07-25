{ lib
, poolName
, disks
, raidLevel ? "raidz1"
, ashift ? "12"
, datasets
}:

{
  disko.devices = {
    disk = lib.listToAttrs (
      lib.imap0
        (i: device: lib.nameValuePair "${poolName}${toString i}" {
          type = "disk";
          inherit device;
          content = {
            type = "gpt";
            partitions.zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = poolName;
              };
            };
          };
        })
        disks
    );

    zpool.${poolName} = {
      type = "zpool";
      mode = raidLevel;
      options.ashift = ashift;
      rootFsOptions = {
        compression = "lz4";
        atime = "off";
        xattr = "sa";
        mountpoint = "legacy";
      };
      mountpoint = "/${poolName}";
      datasets = lib.listToAttrs (
        map
          (d: lib.nameValuePair d.name {
            type = "zfs_fs";
            mountpoint = d.mountpoint;
            options.mountpoint = "legacy";
          })
          datasets
      );
    };
  };
}
