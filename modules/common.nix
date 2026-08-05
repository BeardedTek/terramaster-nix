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

  options.mySystem.domain = lib.mkOption {
    type = lib.types.str;
    description = ''
      Set in variables.nix. The base domain every per-service hostname is
      built from — modules/traefik.nix's LAN/Nebula routers
      (<svc>.<hostName>.$domain, <svc>-<hostName>.nebula.$domain),
      modules/frigate.nix's own vhost, and modules/lldap.nix /
      modules/authelia.nix's LDAP base DN and session cookie domain all
      derive from this one value instead of each hardcoding it separately.
    '';
  };

  options.mySystem.smtp = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.submodule {
        options = {
          host = lib.mkOption { type = lib.types.str; };
          port = lib.mkOption { type = lib.types.port; default = 587; };
          scheme = lib.mkOption {
            type = lib.types.enum [ "smtp" "submission" "submissions" ];
            default = "submission";
          };
          sender = lib.mkOption {
            type = lib.types.str;
            description = "RFC5322 sender address for outgoing notifications.";
          };
          username = lib.mkOption { type = lib.types.str; };
        };
      }
    );
    default = null;
    description = ''
      Set in variables.nix. Connection details for the real upstream mail
      provider — consumed by modules/smtp-relay.nix, which runs a small
      localhost-only OpenSMTPD relay every other service actually talks
      to (unauthenticated, since it's loopback-only), so credentials for
      the real provider live in exactly one place rather than being
      plumbed through every consumer individually. `sender` is reused
      directly by consumers (e.g. modules/authelia.nix's notifier) as
      their own From: address. Null means both the relay and any
      consumer's email notifications are disabled — modules/authelia.nix
      falls back to writing notifications to a local file instead. The
      SMTP password is never set here — it's delivered out-of-repo, see
      secrets/extra-files/persist/etc/opensmtpd/secrets.example and
      docs/DEPLOYMENT.md's secrets table.
    '';
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

  options.mySystem.dashboardSite = lib.mkOption {
    type = lib.types.nullOr lib.types.package;
    default = null;
    description = ''
      The built Hugo dashboard site, set unconditionally by
      modules/dashboard.nix. Read by modules/dashboard-login.nix so its
      login page location can serve straight from the exact same build
      output, without rebuilding an identical derivation a second time.
    '';
  };

  options.mySystem.sso.protectedServices = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          policy = lib.mkOption {
            type = lib.types.enum [ "one_factor" "two_factor" ];
            default = "one_factor";
            description = "Authelia access_control policy for this service's Traefik routers.";
          };
          group = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Restrict to this LLDAP group only; null means any authenticated user.";
          };
        };
      }
    );
    default = { };
    description = ''
      Set by modules/authelia.nix, keyed by the same names as
      modules/traefik.nix's `backends` attrset. Read back by
      modules/traefik.nix to decide which backends get the `authelia`
      ForwardAuth middleware attached — the same "one file computes,
      another consumes" shape mySystem.serviceBackends already
      established between traefik.nix and dashboard.nix.
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
    sso = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          LLDAP directory — see modules/lldap.nix. Off by default; this
          is the master switch for the identity source of truth, turned
          on first and by itself (see mySystem.features.sso.authelia.enable
          for the SSO/forward-auth layer, enabled separately once LLDAP
          alone has been validated).
        '';
      };
      authelia.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Authelia (SSO/forward-auth/OIDC provider), LDAP-backed against
          mySystem.features.sso — see modules/authelia.nix. Kept as its
          own flag, separate from sso.enable, so LLDAP can be deployed and
          validated on its own first (this repo's established phased-
          rollout discipline) before layering forward-auth on top.
        '';
      };
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
