{ config, ... }:

{
  # Minimal config: no cameras yet (added later once real RTSP streams
  # exist), CPU-only object detection for now — a Coral USB TPU is planned
  # but not physically attached yet. Swap detectors.cpu1 for an edgetpu
  # detector once it is (https://docs.frigate.video/configuration/object_detectors).
  # Just enough to confirm the service itself comes up correctly.
  services.frigate = {
    enable = true;
    hostname = "frigate.young.beardedtek.com";
    settings = {
      cameras = { };
      detectors.cpu1.type = "cpu";
    };
  };

  # Frigate's own NixOS module sets up a full nginx vhost (with its own
  # auth_request-based auth flow, go2rtc/vod/jsmpeg proxying) at
  # services.nginx.virtualHosts.${hostname} — by default that binds the
  # standard :80 on every interface, which would collide with Traefik
  # (already the sole owner of :80/:443 on this box). Rebind it to a
  # dedicated port on all interfaces instead — reachable both through
  # Traefik (-> 127.0.0.1:8098) and directly on the LAN/Nebula IPs, same
  # posture as Jellyfin/Sonarr/etc. elsewhere in this repo — and add the
  # Nebula domain as a second name for the SAME vhost via serverAliases
  # rather than needing two separate vhost definitions.
  services.nginx.virtualHosts."frigate.young.beardedtek.com" = {
    listen = [
      {
        addr = "0.0.0.0";
        port = 8098;
      }
      {
        addr = "[::]";
        port = 8098;
      }
    ];
    serverAliases = [ "frigate-young.nebula.beardedtek.com" ];
  };

  networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 8098 ];
  networking.firewall.interfaces.${config.mySystem.lanInterface}.allowedTCPPorts = [ 8098 ];
}
