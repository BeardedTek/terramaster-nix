{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.filebrowser;
  lanIf = config.mySystem.lanInterface;
  hostName = config.networking.hostName;
  domain = config.mySystem.domain;

  port = 8095;
  stateDir = "/var/lib/filebrowser";

  # Native OIDC (Tier A per the SSO plan) rather than the Traefik
  # ForwardAuth gate everything else uses — FileBrowser Quantum handles
  # its own redirect flow directly against Authelia's real OIDC provider,
  # so there's no Traefik middleware involved and no firewall-bypass
  # concern the way there was for Frigate/MinIO (this app's own login,
  # password or OIDC, is unconditionally required regardless of access
  # path). Only active once mySystem.features.sso.authelia.enable is
  # true; config.mySystem.features.sso is read here rather than through
  # candidateOidcClients directly so this file doesn't need to know
  # modules/authelia.nix's internal table shape.
  ssoEnabled = config.mySystem.features.sso.authelia.enable;
  # Plaintext client secret, matching the argon2 digest of the same
  # value registered in modules/authelia.nix's candidateOidcClients —
  # read straight from /persist (Nix eval-time builtins.readFile, same
  # pattern modules/frigate.nix uses for its proxy_auth_secret), not a
  # runtime *File option: pkgs.formats.yaml bakes configFile's values in
  # at build time regardless, so there's no separate runtime read to
  # delegate this to.
  oidcClientSecret = lib.removeSuffix "\n" (builtins.readFile "/persist/etc/filebrowser/oidc_client_secret");

  # Full read/write, not just Quantum's own built-in default (view +
  # download only) — see the comment on the Media/Data sources below
  # for why this is needed on top of the OS-level group permissions.
  defaultPermissions = {
    view = true;
    download = true;
    modify = true;
    create = true;
    delete = true;
  };

  # server.database/cacheDir are absolute paths under this unit's own
  # StateDirectory (systemd creates /var/lib/filebrowser itself, owned by
  # User/Group, as part of that unit's own startup — not via
  # systemd.tmpfiles.rules independently of it. See
  # docs/TROUBLESHOOTING.md's "Freshly-created persistence bind-mounts
  # get the wrong ownership" — this is deliberately the
  # StateDirectory-without-DynamicUser shape that side-steps that race
  # entirely, unlike nixpkgs' own services.minio module, which hit it).
  configFile = (pkgs.formats.yaml { }).generate "filebrowser-config.yaml" {
    server = {
      inherit port;
      database = "${stateDir}/filebrowser.db";
      cacheDir = "${stateDir}/cache";
      # Two named sources, not a bind-mount aggregation trick — Quantum
      # (unlike classic FileBrowser, single `root` only) supports this
      # natively, which is the whole reason this fork was picked. Every
      # other rust/* dataset (config, backups, docker, home, nix,
      # persist) stays unlisted and so stays unreachable through this.
      # config.defaultEnabled: without it, a source exists server-side
      # but isn't actually attached to any user (new or existing) —
      # confirmed the hard way, the bootstrapped admin account saw
      # "Nothing to show here..." for both sources despite correct
      # directory permissions, since Go's zero-value for this field is
      # false ("should be added as a default source for new users?").
      #
      # config.defaultPermissions: without this, Quantum's own
      # built-in default (view+download only, no modify/create/delete)
      # applies to every newly-created non-admin user — confirmed by
      # reading gtsteffaniak/filebrowser's own source
      # (BuiltinDefaultSourceFilePermissions in
      # backend/pkg/settings/source_access.go). The OS-level
      # permissions on /rust/media and /rust/data (group-writable,
      # 2775, filebrowser is in mediagroup — see modules/media-stack.nix)
      # already allow full read/write; this is what actually grants it
      # inside the app for OIDC-created accounts, which otherwise default
      # to read-only regardless. Only takes effect for users created
      # *after* this is set (backend/internal/web/auth.go only calls
      # ApplyUserDefaults in the auto-create-on-first-login branch) — an
      # already-existing non-admin account needs its permissions edited
      # once by hand (Settings -> Users) to pick this up. Note this
      # value is effectively global, not truly per-source, despite
      # living under each source's own config block — Quantum's
      # DefaultSourceFilePermissions() takes the first non-unset one it
      # finds across all sources and applies it to every scope a new
      # user gets, so setting it identically here on both is about
      # clarity, not redundancy.
      sources = [
        {
          path = "/rust/media";
          name = "Media";
          config = { defaultEnabled = true; inherit defaultPermissions; };
        }
        {
          path = "/rust/data";
          name = "Data";
          config = { defaultEnabled = true; inherit defaultPermissions; };
        }
      ];
    };
    auth.methods = {
      password = {
        enabled = true;
        signup = false;
      };
    } // lib.optionalAttrs ssoEnabled {
      oidc = {
        enabled = true;
        createUser = true;
        clientId = "filebrowser";
        clientSecret = oidcClientSecret;
        issuerUrl = "https://auth.${hostName}.${domain}";
        scopes = "openid profile email groups";
        adminGroup = "admins";
      };
    };
  };
in
{
  config = lib.mkIf cfg.enable {
    # mediagroup (modules/media-stack.nix) is what actually gates read
    # access to /rust/media and /rust/data — the same group jellyfin,
    # sonarr, radarr, qbittorrent, and seerr are all in. Without this,
    # filebrowser can authenticate fine but every source comes back
    # empty ("Nothing to show here...") since the filebrowser user can't
    # read either directory at all.
    users.users.filebrowser = {
      isSystemUser = true;
      group = "filebrowser";
      extraGroups = [ "mediagroup" ];
    };
    users.groups.filebrowser = { };

    # Bootstraps the one admin account FileBrowser needs to log in at all
    # — analogous to modules/home-assistant.nix's hass-install-hacs
    # service (a one-shot that only does real work once). Credentials are
    # out-of-repo, same pattern as Traefik's LINODE_TOKEN and MinIO's
    # rootCredentialsFile — see
    # secrets/extra-files/persist/etc/filebrowser/admin.env.example.
    # Guarded on the database file not existing yet: past first boot this
    # becomes a no-op, so a password changed later through the UI is
    # never stomped back to this initial value on a later rebuild.
    systemd.services.filebrowser-setup = {
      description = "Bootstrap FileBrowser's initial admin account";
      before = [ "filebrowser.service" ];
      requiredBy = [ "filebrowser.service" ];
      unitConfig.ConditionPathExists = "!${stateDir}/filebrowser.db";
      serviceConfig = {
        Type = "oneshot";
        User = "filebrowser";
        Group = "filebrowser";
        StateDirectory = "filebrowser";
        EnvironmentFile = "/etc/filebrowser/admin.env";
      };
      script = ''
        ${lib.getExe pkgs.filebrowser-quantum} set -u "$FILEBROWSER_ADMIN_USER,$FILEBROWSER_ADMIN_PASSWORD" -a -c ${configFile}
      '';
    };

    systemd.services.filebrowser = {
      description = "FileBrowser Quantum";
      after = [ "network.target" "filebrowser-setup.service" ];
      requires = [ "filebrowser-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      # /rust/media and /rust/data are pre-existing ZFS mounts, not
      # created by this service — same ordering gap modules/nfs.nix's
      # RequiresMountsFor covers (docs/TROUBLESHOOTING.md's "NFS export
      # script racing its own ZFS mounts"), just for indexed sources
      # instead of an exports file.
      unitConfig.RequiresMountsFor = [ "/rust/media" "/rust/data" ];
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.filebrowser-quantum} -c ${configFile}";
        User = "filebrowser";
        Group = "filebrowser";
        StateDirectory = "filebrowser";
        Restart = "on-failure";
      };
    };

    networking.firewall.interfaces."nebula1".allowedTCPPorts = [ port ];
    networking.firewall.interfaces.${lanIf}.allowedTCPPorts = [ port ];
  };
}
