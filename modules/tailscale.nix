{ config, lib, ... }:

let
  f = config.mySystem.features;
in
{
  config = lib.mkIf f.tailscale.enable {
    services.tailscale = {
      enable = true;
      # Written by modules/dashboard-tailscale.nix — a stable path
      # nixpkgs' own tailscaled-autoconnect.service reads from whenever
      # BackendState isn't already Running, unlike every other credential
      # in this repo there's no out-of-band pre-install delivery for
      # this one: it's entirely pasted through the dashboard after first
      # boot (see that module's own defaultsScript, which seeds an empty
      # placeholder so a fresh box doesn't hit a missing-file error).
      authKeyFile = "/etc/tailscale/authkey";
      # Opens services.tailscale.port (UDP, default 41641) for direct
      # peer connections — falls back to DERP relay otherwise, which
      # still works but adds latency. No manual firewall stanza needed;
      # nixpkgs' own module handles this entirely from this one flag.
      openFirewall = true;
      # Grants the dashboard-tailscale system user permission to run
      # `tailscale status`/etc directly against the local control
      # socket without root — tailscaled's own built-in mechanism for
      # exactly this, used instead of fighting socket permissions.
      extraSetFlags = [ "--operator=dashboard-tailscale" ];
    };

    # tailscaled-autoconnect.service is Type=notify and blocks
    # `systemctl restart` until BackendState reaches Running (or this
    # timeout hits) — explicit rather than trusting an ambient default,
    # since modules/dashboard-tailscale.nix's own apply script waits on
    # this restart synchronously to report success/failure. Same
    # reasoning as every other "a dashboard flow waits on this
    # synchronously" unit this session.
    systemd.services.tailscaled-autoconnect.serviceConfig.TimeoutStartSec = 60;
  };
}
