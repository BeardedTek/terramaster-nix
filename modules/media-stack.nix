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
