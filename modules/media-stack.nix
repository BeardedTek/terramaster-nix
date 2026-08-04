{ config, pkgs, lib, ... }:

let
  f = config.mySystem.features;
  acqEnabled = name: f.mediaAcquisition.enable && f.mediaAcquisition.${name}.enable;

  # openFirewall opens a service's raw port directly, on top of whatever
  # Traefik already routes — harmless for an unprotected service, but a
  # complete bypass of Authelia's ForwardAuth gate for one that's SSO-
  # protected (confirmed the hard way: this is exactly how the Sonarr
  # test service would have had zero effective auth via direct IP:port,
  # despite being gated at the Traefik layer). Keyed the same as
  # modules/traefik.nix's `backends` / mySystem.sso.protectedServices, so
  # a service's direct-port exposure automatically tracks whether it's
  # SSO-gated — no separate flag to remember to flip.
  protected = config.mySystem.sso.protectedServices;
  directlyReachable = name: !(protected ? ${name});
in
{
  config = lib.mkMerge [
    { users.groups.mediagroup = { }; }

    (lib.mkIf f.jellyfin.enable {
      hardware.graphics = {
        enable = true;
        extraPackages = [ pkgs.intel-media-driver ];
      };
      services.jellyfin = {
        enable = true;
        openFirewall = directlyReachable "jellyfin";
        cacheDir = "/var/lib/jellyfin/cache";
      };
      users.users.jellyfin.extraGroups = [ "video" "render" "mediagroup" ];
    })

    (lib.mkIf (acqEnabled "sonarr") {
      services.sonarr.enable = true;
      services.sonarr.openFirewall = directlyReachable "sonarr";
      users.users.sonarr.extraGroups = [ "mediagroup" ];
    })

    (lib.mkIf (acqEnabled "radarr") {
      services.radarr.enable = true;
      services.radarr.openFirewall = directlyReachable "radarr";
      users.users.radarr.extraGroups = [ "mediagroup" ];
    })

    (lib.mkIf (acqEnabled "jackett") {
      services.jackett.enable = true;
      services.jackett.openFirewall = directlyReachable "jackett";
    })

    (lib.mkIf (acqEnabled "qbittorrent") {
      # Deliberately NOT using services.qbittorrent.serverConfig for anything —
      # the module's ExecStartPre unconditionally overwrites the *entire*
      # qBittorrent.conf from the Nix-declared value on every service restart
      # once serverConfig is non-empty, discarding anything qBittorrent itself
      # had written since (WebUI password changes, other settings) — confirmed
      # the hard way: a password set via the WebUI got silently reverted on the
      # next `nixos-rebuild switch`. Its Host-header validation (the reason
      # serverConfig was tried here) is worked around instead on the Traefik
      # side — see modules/traefik.nix.
      services.qbittorrent.enable = true;
      services.qbittorrent.openFirewall = directlyReachable "qbittorrent";
      users.users.qbittorrent.extraGroups = [ "mediagroup" ];
    })

    (lib.mkIf (acqEnabled "seerr") {
      services.seerr = {
        enable = true;
        openFirewall = directlyReachable "seerr";
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
    })
  ];
}
