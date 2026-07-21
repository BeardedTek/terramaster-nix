{
  # This disko config touches ONLY the 256GB internal USB system drive.
  # The `rust` ZFS pool on the 4x6TB HDDs is pre-existing and imported by
  # modules/zfs.nix — it must never appear here, or nixos-anywhere would
  # wipe it during install.
  #
  # CHANGEME: replace with the real by-id path for the USB drive, discovered
  # by running `ls -la /dev/disk/by-id/` on the live installer once booted
  # on the actual hardware (see docs/DEPLOYMENT.md). Never use /dev/sdX —
  # enumeration order isn't guaranteed across reboots/USB re-enumeration.
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
        # No root partition: "/" is tmpfs (see hosts/young/configuration.nix)
        # to minimize writes to the flash drive. Nothing else needs to live
        # on this disk — /nix and /persist are ZFS datasets on `rust`.
      };
    };
  };
}
