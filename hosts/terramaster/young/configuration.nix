{ config, ... }:
{
  system.stateVersion = "26.05";

  networking.hostId = "975edc0d";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "size=2G" "mode=755" ];
  };

  fileSystems."/nix" = {
    device = "rust/nix";
    fsType = "zfs";
    neededForBoot = true;
  };
  fileSystems."/persist" = {
    device = "rust/persist";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/rust" = {
    device = "rust";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "rust/home";
    fsType = "zfs";
  };
  fileSystems."/var/lib/docker" = {
    device = "rust/libdocker";
    fsType = "zfs";
  };
  fileSystems."/rust/media" = {
    device = "rust/media";
    fsType = "zfs";
  };
  fileSystems."/rust/data" = {
    device = "rust/data";
    fsType = "zfs";
  };
  fileSystems."/rust/config" = {
    device = "rust/config";
    fsType = "zfs";
  };
  fileSystems."/rust/minio" = {
    device = "rust/minio";
    fsType = "zfs";
  };
  fileSystems."/rust/immich" = {
    device = "rust/immich";
    fsType = "zfs";
  };
  fileSystems."/rust/backups" = {
    device = "rust/backups";
    fsType = "zfs";
  };
  fileSystems."/rust/docker" = {
    device = "rust/docker";
    fsType = "zfs";
  };

  # Ensures rust/minio and rust/immich exist *before* the mount units
  # above try to mount them — confirmed the hard way: a missing dataset
  # is a hard boot-time mount failure that drops systemd into emergency
  # mode (Immich hit this in production; MinIO's own dataset was already
  # documented as the same known-but-unhit gap, see
  # docs/content/en/docs/architecture/_index.md's MinIO section).
  # Deliberately unconditional, not gated on
  # mySystem.features.minio.enable/immich.enable — the mounts themselves
  # are unconditional too (same as every other /rust/* entry), so the
  # dataset has to exist regardless of whether the service is currently
  # toggled on, or a box with the feature off would hit this exact crash
  # the moment this config syncs (which is exactly what happened —
  # Immich wasn't even enabled yet).
  #
  # Ordered after/requires "rust.mount" (the already-existing top-level
  # /rust mount) rather than a hand-guessed zfs-import-rust.service name
  # — if /rust itself is successfully mounted, the pool is definitely
  # already imported, so this gets correct pool-import ordering for free
  # from a unit we already know exists. before/requiredBy the target's
  # own mount unit (systemd's standard, deterministic path-to-unit-name
  # escaping: /rust/X -> rust-X.mount) is what actually inserts this
  # *before* the mount attempt; requiredBy is what pulls it into the
  # boot graph at all, equivalent to the mount unit itself declaring
  # Requires=zfs-ensure-X-dataset.service.
  #
  # Only ever creates, never destroys — disabling a service must never
  # delete its data. No `zfs destroy` anywhere in this repo, deliberately.
  systemd.services."zfs-ensure-minio-dataset" = {
    description = "Ensure the rust/minio ZFS dataset exists before mounting it";
    after = [ "rust.mount" ];
    requires = [ "rust.mount" ];
    before = [ "rust-minio.mount" ];
    requiredBy = [ "rust-minio.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if ! ${config.boot.zfs.package}/bin/zfs list "rust/minio" >/dev/null 2>&1; then
        ${config.boot.zfs.package}/bin/zfs create "rust/minio"
      fi
    '';
  };
  systemd.services."zfs-ensure-immich-dataset" = {
    description = "Ensure the rust/immich ZFS dataset exists before mounting it";
    after = [ "rust.mount" ];
    requires = [ "rust.mount" ];
    before = [ "rust-immich.mount" ];
    requiredBy = [ "rust-immich.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if ! ${config.boot.zfs.package}/bin/zfs list "rust/immich" >/dev/null 2>&1; then
        ${config.boot.zfs.package}/bin/zfs create "rust/immich"
      fi
    '';
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/etc/nebula"
      "/etc/traefik"
      "/var/lib/samba"
      "/var/lib/jellyfin"
      # Not a plain string like the others: nixpkgs' own Plex module
      # only chowns /var/lib/plex to plex:plex the *first* time it's
      # created (guarded on `! test -d "$PLEX_DATADIR"` in its
      # ExecStartPre) — impermanence creating it first (root:root 0755,
      # the plain-string default) means that guard sees it already
      # exists and skips the chown, leaving Plex's own unprivileged
      # `plex` user unable to write into its own data directory.
      # Confirmed the hard way: "mkdir: cannot create directory
      # '/var/lib/plex/.skeleton': Permission denied". Matches Plex's
      # own `install -d -m 0755 -o plex -g plex` exactly, so its guard
      # sees correct ownership already in place and no-ops cleanly.
      { directory = "/var/lib/plex"; user = "plex"; group = "plex"; mode = "0755"; }
      "/var/lib/sonarr"
      "/var/lib/radarr"
      "/var/lib/jackett"
      "/var/lib/seerr"
      "/var/lib/qBittorrent"
      "/var/lib/traefik"
      "/var/lib/frigate"
      "/var/lib/hass"
      "/var/lib/mosquitto"
      "/etc/minio"
      "/var/lib/filebrowser"
      "/etc/filebrowser"
      "/etc/lldap"
      # Not "/var/lib/lldap": modules/lldap.nix's services.lldap runs
      # with DynamicUser = true, and systemd's own DynamicUser handling
      # wants to own that path itself (rename it to /var/lib/private/lldap
      # on first start, then symlink /var/lib/lldap back to it) —
      # confirmed the hard way, that rename() fails with "Device or
      # resource busy" when impermanence has already bind-mounted
      # /var/lib/lldap from /persist. Persisting /var/lib/private itself
      # (the parent, not just .../lldap) sidesteps the conflict: nothing
      # else claims /var/lib/lldap, so systemd's own symlink dance
      # proceeds normally, and lldap's subdirectory comes along for free
      # since it lives inside the now-persisted parent.
      #
      # mode = "0700" matters and isn't the impermanence default (0755):
      # systemd refuses to use /var/lib/private at all if it's more
      # permissive than 0700 — confirmed the hard way, second failure
      # after the path fix above ("mode 0755 that is too permissive
      # (0700 was requested), refusing"). Also confirmed: impermanence
      # only applies user/group/mode when *creating* a directory that
      # doesn't yet exist in persistent storage — it won't retroactively
      # fix one already created wrong, so a directory created before this
      # change needs a manual `chmod 0700` once, not just this edit.
      { directory = "/var/lib/private"; user = "root"; group = "root"; mode = "0700"; }
      "/etc/authelia"
      "/var/lib/authelia-main"
      "/etc/opensmtpd"
      "/etc/jellyfin"
      "/etc/dashboard-login"
      "/etc/unix-ldap-login"
      "/etc/vaultwarden"
      "/var/lib/vaultwarden"
      "/etc/tailscale"
      "/var/lib/tailscale"
      # Scrutiny's own DB doesn't need an entry here — it runs with
      # DynamicUser = true (see modules/scrutiny.nix), so it's already
      # covered by the /var/lib/private entry above, same reasoning as
      # lldap's. InfluxDB2 (Scrutiny's historical-trends backend) runs
      # as its own stable user instead, so it needs the usual explicit
      # entry — without it, every SMART history graph would reset on
      # each reboot.
      "/var/lib/influxdb2"
      # scrutiny-collector-bootstrap's own stamp file (see
      # modules/scrutiny.nix) — without persisting this, the "only ever
      # once" guard would instead become "once every reboot", since a
      # tmpfs root wipes it on every restart.
      "/var/lib/scrutiny-collector-state"
      # PostgreSQL (first pulled in by Immich, modules/immich.nix) is
      # its own stable "postgres" user, not DynamicUser, so it needs
      # the usual explicit entry — but *structured*, not a plain
      # string, learned from the exact Plex ownership bug above:
      # impermanence's plain-string default (root:root 0755) would
      # leave the postgres user unable to write into its own data
      # directory on initdb, and separately, postgres itself refuses
      # to start at all against anything more permissive than 0700
      # (same class of failure as /var/lib/private above).
      { directory = "/var/lib/postgresql"; user = "postgres"; group = "postgres"; mode = "0700"; }
      # Immich's own StateDirectory/CacheDirectory (modules/immich.nix)
      # — unlike Plex's hand-written prestart script, systemd's native
      # StateDirectory=/CacheDirectory= re-asserts ownership on every
      # start regardless of prior state, so a plain string is safe
      # here. The bulk photo/video library itself lives on the rust
      # pool (/rust/immich, mediaLocation), not under here at all.
      "/var/lib/immich"
      # ML model weights (~hundreds of MB from Hugging Face) — without
      # this, machine-learning.enable would re-download them on every
      # reboot instead of reusing what's already been fetched.
      "/var/cache/immich"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
}
