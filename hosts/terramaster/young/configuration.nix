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
      "/var/lib/minio"
      "/etc/minio"
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
