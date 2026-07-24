{
  disko.devices.disk.usb = {
    device = "/dev/disk/by-id/usb-_USB_DISK_3.0_070D55621A83CB64-0:0";
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
