{ config, lib, pkgs, ... }:

{
  options.mySystem.lanInterface = lib.mkOption {
    type = lib.types.str;
    default = "enp1s0";
    description = "Name of the physical LAN interface";
  };

  options.mySystem.serviceBackends = lib.mkOption {
    type = lib.types.attrsOf lib.types.port;
    default = { };
    description = ''
      Service name -> local port. Single source of truth, set by
      modules/traefik.nix and read by modules/dashboard.nix (for its
      per-service up/down checks) — avoids the two modules maintaining
      separate copies of the same list.
    '';
  };

  options.mySystem.contactInfo = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          label = lib.mkOption {
            type = lib.types.str;
            description = "e.g. \"Tech Support\", \"Sales\", \"Customer Support\".";
          };
          email = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          phone = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
        };
      }
    );
    default = [ ];
    description = ''
      NAS admin contact entries, set per-host (e.g.
      hosts/young/configuration.nix) — read by modules/dashboard.nix and
      passed into the Hugo build as data/contact.json, so the same list
      shows up in both the dashboard's footer and its Help page without
      being hardcoded into the site content itself.
    '';
  };

  config = {
    time.timeZone = "America/Anchorage";
    i18n.defaultLocale = "en_US.UTF-8";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    nix.settings.trusted-users = [ "@wheel" ];

    boot.initrd.systemd.emergencyAccess = true;

    networking.firewall.enable = true;

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    networking.firewall.interfaces.${config.mySystem.lanInterface}.allowedTCPPorts = [ 22 ];
    networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 22 ];

    system.autoUpgrade.enable = false;

    environment.systemPackages = with pkgs; [
      vim
      git
      smartmontools
    ];
  };
}
