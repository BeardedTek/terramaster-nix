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
      # Applied via nixpkgs' own tailscaled-set.service (a oneshot that
      # runs `tailscale set <these flags>` on every boot/rebuild where
      # they change) — explicit =true/=false on every boolean rather
      # than omitting when false, so toggling a Service Configuration
      # checkbox off actually clears it on the next rebuild instead of
      # just "not asking" to turn it off. --operator grants the
      # dashboard-tailscale system user permission to run `tailscale
      # status`/etc directly against the local control socket without
      # root — tailscaled's own built-in mechanism for exactly this,
      # used instead of fighting socket permissions.
      extraSetFlags = [
        "--accept-dns=${lib.boolToString f.tailscale.acceptDns}"
        "--accept-routes=${lib.boolToString f.tailscale.acceptRoutes}"
        "--advertise-exit-node=${lib.boolToString f.tailscale.advertiseExitNode}"
        "--advertise-routes=${f.tailscale.advertiseRoutes}"
        "--operator=dashboard-tailscale"
      ];
      # "client" (loose reverse-path filtering) covers acceptRoutes;
      # "server" (IP forwarding) covers advertising either an exit node
      # or subnet routes — combined into "both" when this box does
      # both. See nixpkgs' own option description for exactly what
      # each setting enables.
      useRoutingFeatures =
        let
          advertising = f.tailscale.advertiseExitNode || f.tailscale.advertiseRoutes != "";
        in
        if advertising && f.tailscale.acceptRoutes then "both"
        else if advertising then "server"
        else if f.tailscale.acceptRoutes then "client"
        else "none";
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
