{ lib, pkgs, ... }:

{
  options.mySystem.lanInterface = lib.mkOption {
    type = lib.types.str;
    default = "CHANGEME-lan-if";
    description = ''
      Name of the physical LAN interface (find with `ip link` on the live
      installer, e.g. eno1/enp1s0). Single source of truth, used by
      modules/samba.nix and modules/nfs.nix for firewall scoping, and by
      modules/nfs.nix to auto-detect the currently-live LAN subnet for NFS
      exports.
    '';
  };

  config = {
    time.timeZone = "America/Chicago";
    i18n.defaultLocale = "en_US.UTF-8";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

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
