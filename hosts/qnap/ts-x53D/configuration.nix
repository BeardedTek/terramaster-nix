{ config, lib, ... }:
let
  f = config.mySystem.features;
in
{
  system.stateVersion = "26.05";

  networking.hostId = "dd354f3f";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "size=2G" "mode=755" ];
  };

  fileSystems."/nix".neededForBoot = true;
  fileSystems."/persist".neededForBoot = true;

  fileSystems."/rust/minio" = lib.mkIf f.minio.enable {
    device = "rust/minio";
    fsType = "zfs";
  };
  systemd.services."zfs-ensure-minio-dataset" = lib.mkIf f.minio.enable {
    description = "Ensure the rust/minio ZFS dataset exists before mounting it";
    # DefaultDependencies = false is required, not cosmetic: without it
    # this oneshot picks up systemd's normal After=basic.target, which
    # pulls in sockets.target -> every enabled .socket unit (e.g.
    # fcgiwrap-dashboard-nebula.socket) -> sysinit.target ->
    # systemd-update-done.service -> local-fs.target — closing a real
    # ordering cycle back to "rust-minio.mount", since that mount
    # unit's own Before=local-fs.target makes local-fs.target implicitly
    # After= it. Confirmed the hard way in a real Tier 2 VM boot:
    # systemd silently breaks the cycle by deleting
    # "rust-minio.mount"'s own start job, so the ensure-service
    # still runs and creates the dataset, but the mount itself never
    # happens and the dependent service (e.g. minio.service) just sits
    # inactive with no error surfaced anywhere obvious. Early-boot-only
    # oneshots that must run before a specific local mount need this,
    # same as systemd-fsck@ and other early mount helpers.
    unitConfig.DefaultDependencies = false;
    after = [ "rust.mount" ];
    requires = [ "rust.mount" ];
    before = [ "rust-minio.mount" "local-fs.target" ];
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
  fileSystems."/rust/immich" = lib.mkIf f.immich.enable {
    device = "rust/immich";
    fsType = "zfs";
  };
  systemd.services."zfs-ensure-immich-dataset" = lib.mkIf f.immich.enable {
    description = "Ensure the rust/immich ZFS dataset exists before mounting it";
    # DefaultDependencies = false is required, not cosmetic: without it
    # this oneshot picks up systemd's normal After=basic.target, which
    # pulls in sockets.target -> every enabled .socket unit (e.g.
    # fcgiwrap-dashboard-nebula.socket) -> sysinit.target ->
    # systemd-update-done.service -> local-fs.target — closing a real
    # ordering cycle back to "rust-immich.mount", since that mount
    # unit's own Before=local-fs.target makes local-fs.target implicitly
    # After= it. Confirmed the hard way in a real Tier 2 VM boot:
    # systemd silently breaks the cycle by deleting
    # "rust-immich.mount"'s own start job, so the ensure-service
    # still runs and creates the dataset, but the mount itself never
    # happens and the dependent service (e.g. minio.service) just sits
    # inactive with no error surfaced anywhere obvious. Early-boot-only
    # oneshots that must run before a specific local mount need this,
    # same as systemd-fsck@ and other early mount helpers.
    unitConfig.DefaultDependencies = false;
    after = [ "rust.mount" ];
    requires = [ "rust.mount" ];
    before = [ "rust-immich.mount" "local-fs.target" ];
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
      { directory = "/var/lib/plex"; user = "plex"; group = "plex"; mode = "0755"; }
      "/var/lib/sonarr"
      "/var/lib/radarr"
      "/var/lib/jackett"
      "/var/lib/seerr"
      "/var/lib/qBittorrent"
      "/var/lib/traefik"
      "/var/lib/frigate"
      { directory = "/var/lib/hass"; user = "hass"; group = "hass"; mode = "0755"; }
      { directory = "/var/lib/mosquitto"; user = "mosquitto"; group = "mosquitto"; mode = "0755"; }
      "/etc/minio"
      "/var/lib/filebrowser"
      "/etc/filebrowser"
      # AdGuard Home's own state (users, blocklists, everything set
      # through its web UI) is already covered by the "/var/lib/private"
      # entry below — it runs with DynamicUser = true. This is only for
      # modules/dns-cache.nix's own bootstrap admin.env + rewrite-sync
      # state, unrelated to AGH's internals.
      "/etc/adguardhome"
      "/etc/lldap"
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
      "/var/lib/influxdb2"
      "/var/lib/scrutiny-collector-state"
      { directory = "/var/lib/private"; user = "root"; group = "root"; mode = "0700"; }
      { directory = "/var/lib/postgresql"; user = "postgres"; group = "postgres"; mode = "0700"; }
      "/var/lib/immich"
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
