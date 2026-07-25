{ config, lib, pkgs, ... }:

{
  options.mySystem.lanInterface = lib.mkOption {
    type = lib.types.str;
    default = "enp1s0";
    description = "Name of the physical LAN interface";
  };

  options.mySystem.security.sshPasswordAuth = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Allow password-based SSH login. Defaults to false (key-only,
      young's own posture — see docs/ARCHITECTURE.md's "Network and
      firewall model" section). The installer wizard offers turning this
      on as a fallback for instances provisioned without an SSH public
      key on hand (no GitHub username to fetch from, no USB drive with
      one staged) — root login stays disabled either way.
    '';
  };

  options.mySystem.manufacturer = lib.mkOption {
    type = lib.types.str;
    description = ''
      Set in variables.nix. Together with mySystem.model, selects
      hosts/<manufacturer>/<model>/ as the hardware profile (disko.nix,
      configuration.nix) flake.nix imports for this box — see
      docs/ARCHITECTURE.md's "variables.nix" section.
    '';
  };

  options.mySystem.model = lib.mkOption {
    type = lib.types.str;
    description = "Set in variables.nix, alongside mySystem.manufacturer.";
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

  options.mySystem.features = {
    jellyfin.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    frigate.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    minio.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "S3-compatible object storage (MinIO) — see modules/minio.nix.";
    };
    filebrowser.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Web-based file browser (FileBrowser Quantum) over /rust/media and
        /rust/data — see modules/filebrowser.nix. Exposed as the "files"
        Traefik backend.
      '';
    };
    selfUpdate.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Dashboard-triggered self-update: checks GitHub Releases hourly,
        and a password-gated button on the dashboard fetches the latest
        tag and runs nixos-rebuild switch — see modules/self-update.nix.
      '';
    };
    homeAssistant = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Home Assistant, its Mosquitto broker, and its Samba share.";
      };
      zwave.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      hacs.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
    mediaAcquisition = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Seerr, Radarr, Sonarr, Jackett, qBittorrent group.";
      };
      seerr.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      radarr.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      sonarr.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      jackett.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      qbittorrent.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  };

  options.mySystem.users = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          name = lib.mkOption { type = lib.types.str; };
          wheel = lib.mkOption { type = lib.types.bool; default = false; };
        };
      }
    );
    default = [ ];
    description = ''
      Normal user accounts to create (see variables.nix), implemented by
      modules/users.nix. Each account's initial password hash comes from
      the environment variable <NAME_UPPERCASE>_INITIAL_HASH — see
      secrets/initial-passwords.env.example — never written into the repo.
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
      NAS admin contact entries, set in variables.nix — read by
      modules/dashboard.nix and passed into the Hugo build as
      data/contact.json, so the same list shows up in both the dashboard's
      footer and its Help page without being hardcoded into the site
      content itself.
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
        PasswordAuthentication = config.mySystem.security.sshPasswordAuth;
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
