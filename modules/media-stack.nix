{ pkgs, ... }:

{
  # Root is tmpfs, so each service's default /var/lib/<service> state dir
  # (jellyfin/sonarr/radarr/jackett metadata/config/DBs) is persisted via
  # environment.persistence in hosts/young/configuration.nix rather than
  # relying on a per-module "dataDir" option — safer than assuming every
  # module exposes one, since that wasn't verified against the pinned
  # nixpkgs source.

  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.intel-media-driver ]; # iHD driver — required for
    # N-series Intel (Jasper Lake/Alder Lake-N); the older i965/vaapiIntel
    # driver does not support this generation.
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
  users.users.jellyfin.extraGroups = [ "video" "render" ];
  # After deploy: Dashboard -> Playback -> enable VAAPI against the correct
  # /dev/dri/renderD* device (this is Jellyfin app config, not a Nix option).

  services.sonarr.enable = true;
  services.sonarr.openFirewall = true;

  services.radarr.enable = true;
  services.radarr.openFirewall = true;

  services.jackett.enable = true;
  services.jackett.openFirewall = true;

  # Jellyseerr's upstream project merged with Overseerr and renamed to
  # "Seerr" — nixpkgs 26.05 ships a native, sandboxed systemd service for
  # it (services.jellyseerr is auto-renamed to services.seerr by the
  # module itself). No container runtime needed at all for this stack.
  services.seerr = {
    enable = true;
    openFirewall = true;
    # port defaults to 5055
  };

  # No virtualisation.* here on purpose — nothing in this config needs a
  # container runtime anymore now that Seerr runs natively.
}
