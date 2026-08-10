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
    plex.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Plex Media Server — see modules/plex.nix. Sits alongside
        Jellyfin under "Media Playback"; authentication is a real
        plex.tv account (set up through Plex's own first-run web
        wizard), so — same posture as Jellyfin's own LDAP auth — it's
        not in mySystem.sso.protectedServices.
      '';
    };
    immich.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Immich — self-hosted photo/video library and mobile backup,
        see modules/immich.nix. First service on this box to pull in
        PostgreSQL (with pgvector) and Redis. Real account-based auth
        of its own, same posture as Jellyfin/Plex — not in
        mySystem.sso.protectedServices.
      '';
    };
    immich.machineLearning.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Face recognition, CLIP smart search, and duplicate detection —
        see modules/immich.nix. Off by default: nixpkgs only packages
        a CPU-only build of immich-machine-learning (no OpenVINO/CUDA
        acceleration), so this is genuinely heavy on NAS-class
        hardware, especially the one-time backfill over an existing
        library. Dashboard-editable on Service Configuration,
        rebuild-driven like Vaultwarden's signupsAllowed.
      '';
    };
    immich.publicProxy.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        immich-public-proxy — a narrow reverse-proxy that only serves
        public share links, so a shared album can be exposed without
        opening up the full Immich app/API. See modules/immich.nix.
        Dashboard-editable, rebuild-driven.
      '';
    };
    frigate.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    nebula.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Nebula overlay mesh VPN — see modules/nebula.nix. Also gates
        Traefik's *.nebula.<domain> wildcard cert request and the
        nebula-domain router for every backend service
        (modules/traefik.nix) — no point requesting/serving a cert for a
        mesh that isn't running. Defaults to true (not false, unlike the
        other opt-in flags here) because Nebula ran unconditionally on
        every host before this flag existed; still needs
        /etc/nebula/config.yaml delivered out-of-band regardless of this
        setting (see hosts/installer/wizard/stages/70-secrets.sh).
      '';
    };
    tailscale.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Tailscale mesh VPN — see modules/tailscale.nix. Sits alongside
        Nebula under the "Mesh VPN Networks" group; unlike Nebula,
        authentication is entirely dashboard-driven (paste an auth key
        generated at login.tailscale.com/admin/settings/keys on the
        Service Configuration page — modules/dashboard-tailscale.nix),
        no out-of-band secret delivery needed.
      '';
    };
    tailscale.acceptDns = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Accept DNS settings (MagicDNS) pushed by the tailnet — see
        modules/tailscale.nix's extraSetFlags. Dashboard-editable on
        the Service Configuration page (modules/dashboard-svcconfig.nix),
        rebuild-driven like Vaultwarden's signupsAllowed.
      '';
    };
    tailscale.acceptRoutes = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Accept subnet routes and exit nodes advertised by other
        tailnet devices — see modules/tailscale.nix's extraSetFlags
        and useRoutingFeatures. Dashboard-editable, rebuild-driven.
      '';
    };
    tailscale.advertiseExitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Advertise this box itself as an exit node other tailnet
        devices can route all their traffic through — see
        modules/tailscale.nix's extraSetFlags and useRoutingFeatures
        (needs IP forwarding enabled, handled there). Dashboard-
        editable, rebuild-driven.
      '';
    };
    tailscale.advertiseRoutes = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Comma-separated CIDR list of subnet routes this box advertises
        to the tailnet (e.g. "192.168.3.0/24") — see
        modules/tailscale.nix's extraSetFlags and useRoutingFeatures.
        Empty clears any previously advertised routes. Dashboard-
        editable, rebuild-driven.
      '';
    };
    minio.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "S3-compatible object storage (MinIO) — see modules/minio.nix.";
    };
    scrutiny.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Scrutiny — hard drive S.M.A.R.T monitoring and historical
        trends, see modules/scrutiny.nix. No login of its own, so it
        sits behind Authelia's ForwardAuth gate like Sonarr
        (modules/authelia.nix's candidateProtectedServices), not left
        open like Vaultwarden/MinIO which have their own auth.
      '';
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
    vaultwarden = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Vaultwarden (self-hosted Bitwarden-compatible password
          manager) — see modules/vaultwarden.nix. No OIDC/SSO support in
          the open-source build, so unlike most other services here
          it's deliberately never added to
          mySystem.sso.protectedServices — its own master-password +
          TOTP/WebAuthn login is the trust boundary, reached directly
          through Traefik.
        '';
      };
      signupsAllowed = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether new accounts can self-register. The one Vaultwarden
          setting genuinely safe to expose for editing — see the
          "Password Manager" block on the Service Configuration page
          (modules/dashboard-svcconfig.nix). Defaults to false
          (invite-only via the ADMIN_TOKEN-gated /admin panel) since
          this box may be reachable outside the LAN.
        '';
      };
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
      authelia.theme = lib.mkOption {
        type = lib.types.enum [ "light" "dark" "auto" ];
        default = "auto";
        description = ''
          Authelia's own UI theme — see modules/authelia.nix's
          settings.theme and the "SSO / Authelia" block on the Service
          Configuration page (modules/dashboard-svcconfig.nix). The one
          Authelia setting in that file that's genuinely safe to expose
          for editing — everything else there is either derived from
          mySystem.domain/hostName or security-critical (session, LDAP,
          access_control), left hardcoded on purpose.
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
