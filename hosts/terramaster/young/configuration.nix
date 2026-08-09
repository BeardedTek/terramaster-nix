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
  fileSystems."/rust/backups" = {
    device = "rust/backups";
    fsType = "zfs";
  };
  fileSystems."/rust/docker" = {
    device = "rust/docker";
    fsType = "zfs";
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/etc/nebula"
      "/etc/traefik"
      "/var/lib/samba"
      "/var/lib/jellyfin"
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
