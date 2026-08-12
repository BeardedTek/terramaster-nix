{ config, lib, pkgs, ... }:

let
  f = config.mySystem.features;

  # Same derivation as modules/media-stack.nix's own directlyReachable —
  # duplicated rather than imported since that module is Jellyfin/media-
  # acquisition-specific and this one deliberately isn't wired into it
  # (Plex needs none of Jellyfin's LDAP-plugin machinery). Opens Plex's
  # raw ports directly on top of Traefik unless it's ever added to
  # mySystem.sso.protectedServices — harmless today since Plex has its
  # own real auth (a plex.tv account) and isn't in that set.
  protected = config.mySystem.sso.protectedServices;
  directlyReachable = name: !(protected ? ${name});
in
{
  config = lib.mkIf f.plex.enable {
    # plexmediaserver is the first unfree package this flake pulls in —
    # scoped to just this one name rather than a blanket
    # nixpkgs.config.allowUnfree = true, so enabling Plex doesn't
    # silently also permit every other unfree package anywhere else in
    # the tree.
    nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "plexmediaserver";

    # Same hardware-transcoding setup as modules/media-stack.nix's own
    # Jellyfin block — safe to define alongside it too: both enabled at
    # once just merges into one `hardware.graphics.enable = true` and a
    # two-entry (harmlessly duplicated) extraPackages list.
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver            # iHD VA-API driver
        # See modules/media-stack.nix's own copy of this list for why
        # this is intel-compute-runtime-legacy1, not mainline
        # intel-compute-runtime (mainline reports zero OpenCL platforms
        # on Jasper Lake/Gen11 hardware — confirmed on young).
        intel-compute-runtime-legacy1
        vpl-gpu-rt                    # Intel VPL runtime — modern Quick Sync
      ];
    };
    # Forwards the real /etc/OpenCL/vendors to the merged extraPackages
    # env — see modules/media-stack.nix's own copy of this line for the
    # full rationale (ocl-icd, which ffmpeg links against, never looks
    # at /run/opengl-driver itself). Same identical value declared
    # again here, harmlessly, matching how hardware.graphics.enable
    # itself is already declared redundantly across these three files.
    environment.etc."OpenCL/vendors".source = "/run/opengl-driver/etc/OpenCL/vendors";

    services.plex = {
      enable = true;
      openFirewall = directlyReachable "plex";
    };

    # video/render for hardware transcoding, mediagroup for read access
    # to /rust/media — exactly Jellyfin's own treatment
    # (modules/media-stack.nix). Library paths themselves aren't set
    # here; Plex manages those through its own first-run web setup, same
    # as Jellyfin.
    users.users.plex.extraGroups = [ "video" "render" "mediagroup" ];
  };
}
