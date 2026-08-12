{ config, lib, pkgs, ... }:

let
  f = config.mySystem.features;

  # Same derivation as modules/media-stack.nix's/modules/plex.nix's own
  # directlyReachable — duplicated rather than imported for the same
  # reason plex.nix does: this module doesn't otherwise depend on
  # media-stack.nix. Opens Immich's raw port directly on top of Traefik
  # unless it's ever added to mySystem.sso.protectedServices — harmless
  # today since Immich has its own real account-based auth and isn't in
  # that set.
  protected = config.mySystem.sso.protectedServices;
  directlyReachable = name: !(protected ? ${name});

  # Bulk photo/video storage belongs on the ZFS pool, not mixed into
  # /persist's system-state role — same reasoning as MinIO's own
  # dedicated rust/minio dataset. Mount itself is declared in
  # hosts/terramaster/young/configuration.nix's fileSystems, matching
  # rust/media, rust/data, rust/minio; the dataset has to exist first
  # (`zfs create rust/immich`, out-of-band like every other rust/*
  # dataset — this repo doesn't manage the pool itself via disko).
  mediaLocation = "/rust/immich";
in
{
  config = lib.mkMerge [
    (lib.mkIf f.immich.enable {
      # Same hardware-transcoding setup as modules/plex.nix/
      # modules/media-stack.nix's own Jellyfin block — safe to define
      # alongside either: enabling more than one just merges into one
      # hardware.graphics.enable = true and a harmlessly-duplicated
      # extraPackages list.
      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver     # iHD VA-API driver
          intel-compute-runtime  # OpenCL runtime — required for tone mapping
          vpl-gpu-rt             # Intel VPL runtime — modern Quick Sync
        ];
      };
      # Forwards the real /etc/OpenCL/vendors to the merged extraPackages
      # env — see modules/media-stack.nix's own copy of this line for the
      # full rationale (ocl-icd, which ffmpeg links against, never looks
      # at /run/opengl-driver itself). Same identical value declared
      # again here, harmlessly, matching how hardware.graphics.enable
      # itself is already declared redundantly across these three files.
      environment.etc."OpenCL/vendors".source = "/run/opengl-driver/etc/OpenCL/vendors";

      services.immich = {
        enable = true;
        # Unlike Plex's own module (which already defaults to allowing
        # every device), Immich's accelerationDevices defaults to `[ ]`
        # — no hardware transcoding at all unless explicitly listed.
        accelerationDevices = [ "/dev/dri/renderD128" ];
        # Broad bind (matches Jellyfin's own default) rather than
        # Vaultwarden/Scrutiny's 127.0.0.1-only — openFirewall below is
        # what actually decides whether that's reachable off-box.
        host = "0.0.0.0";
        inherit mediaLocation;
        machine-learning.enable = f.immich.machineLearning.enable;
        openFirewall = directlyReachable "immich";
      };

      # video/render for hardware transcoding — same grant Jellyfin/Plex
      # already get via their own extraGroups.
      users.users.immich.extraGroups = [ "video" "render" ];
    })

    (lib.mkIf (f.immich.enable && f.immich.publicProxy.enable) {
      services.immich-public-proxy = {
        enable = true;
        immichUrl = "http://127.0.0.1:${toString config.services.immich.port}";
      };
    })
  ];
}
