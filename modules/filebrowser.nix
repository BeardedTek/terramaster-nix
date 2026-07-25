{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.filebrowser;
  lanIf = config.mySystem.lanInterface;

  port = 8095;
  stateDir = "/var/lib/filebrowser";

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
      sources = [
        { path = "/rust/media"; name = "Media"; config.defaultEnabled = true; }
        { path = "/rust/data"; name = "Data"; config.defaultEnabled = true; }
      ];
    };
    auth.methods.password = {
      enabled = true;
      signup = false;
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
