{ pkgs, lib, ... }:

{
  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.intel-media-driver ];
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    cacheDir = "/var/lib/jellyfin/cache";
  };
  users.users.jellyfin.extraGroups = [ "video" "render" "mediagroup" ];

  services.sonarr.enable = true;
  services.sonarr.openFirewall = true;
  users.users.sonarr.extraGroups = [ "mediagroup" ];

  services.radarr.enable = true;
  services.radarr.openFirewall = true;
  users.users.radarr.extraGroups = [ "mediagroup" ];

  services.jackett.enable = true;
  services.jackett.openFirewall = true;

  users.groups.mediagroup = { };

  services.qbittorrent.enable = true;
  services.qbittorrent.openFirewall = true;
  users.users.qbittorrent.extraGroups = [ "mediagroup" ];
  # Deliberately NOT using services.qbittorrent.serverConfig for anything —
  # the module's ExecStartPre unconditionally overwrites the *entire*
  # qBittorrent.conf from the Nix-declared value on every service restart
  # once serverConfig is non-empty, discarding anything qBittorrent itself
  # had written since (WebUI password changes, other settings) — confirmed
  # the hard way: a password set via the WebUI got silently reverted on the
  # next `nixos-rebuild switch`. Its Host-header validation (the reason
  # serverConfig was tried here) is worked around instead on the Traefik
  # side — see modules/traefik.nix.

  services.seerr = {
    enable = true;
    openFirewall = true;
    # port defaults to 5055
  };

  users.users.seerr = {
    isSystemUser = true;
    group = "seerr";
    extraGroups = [ "mediagroup" ];
  };
  users.groups.seerr = { };
  systemd.services.seerr.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "seerr";
    Group = "seerr";
  };
  
}
