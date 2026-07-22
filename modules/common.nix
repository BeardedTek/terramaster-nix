{ lib, pkgs, ... }:

{
  options.mySystem.lanInterface = lib.mkOption {
    type = lib.types.str;
    default = "enp1s0";
    description = ''
      Name of the physical LAN interface (find with `ip link` on the live
      installer, e.g. eno1/enp1s0). Single source of truth, used by
      modules/samba.nix and modules/nfs.nix for firewall scoping, and by
      modules/nfs.nix to auto-detect the currently-live LAN subnet for NFS
      exports.
    '';
  };

  config = {
    time.timeZone = "America/Anchorage";
    i18n.defaultLocale = "en_US.UTF-8";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # users.mutableUsers = false with no root password means root has no
    # valid credentials anywhere, including the initrd's own emergency
    # shell — a failed early-boot mount (e.g. a ZFS import hiccup) becomes
    # completely unrecoverable without physical installer media. This
    # grants an unauthenticated emergency shell in the initrd specifically
    # so that kind of failure is debuggable from the box itself.
    boot.initrd.systemd.emergencyAccess = true;

    networking.firewall.enable = true;

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # No auto-reboot: an unexpected reboot mid-scrub/mid-resilver on a NAS
    # is worse than a delayed update. Rebuild/reboot manually on your own
    # schedule.
    system.autoUpgrade.enable = false;

    environment.systemPackages = with pkgs; [
      vim
      git
      smartmontools
    ];
  };
}
