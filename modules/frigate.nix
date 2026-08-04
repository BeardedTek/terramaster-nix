{ config, lib, ... }:

let
  hostName = config.networking.hostName;
  domain = config.mySystem.domain;
  vhost = "frigate.${hostName}.${domain}";

  # Only open Frigate's own port directly when it isn't SSO-gated —
  # otherwise http://<ip>:8098 bypasses Authelia's ForwardAuth middleware
  # entirely (Traefik/Authelia never see the request; nginx here is
  # listening on all interfaces regardless, so the firewall is the only
  # thing actually controlling reachability). See modules/media-stack.nix
  # for the same pattern applied to the media-acquisition services.
  directlyReachable = !(config.mySystem.sso.protectedServices ? frigate);
in
{
  config = lib.mkIf config.mySystem.features.frigate.enable {
    services.frigate = {
      enable = true;
      hostname = vhost;
      settings = {
        cameras = { };
        detectors.cpu1.type = "cpu";
      };
    };

    services.nginx.virtualHosts.${vhost} = {
      listen = [
        { addr = "0.0.0.0"; port = 8098; }
        { addr = "[::]"; port = 8098; }
      ];
      serverAliases = [ "frigate-${hostName}.nebula.${domain}" ];
    };

    networking.firewall.interfaces."nebula1".allowedTCPPorts = lib.optionals directlyReachable [ 8098 ];
    networking.firewall.interfaces.${config.mySystem.lanInterface}.allowedTCPPorts = lib.optionals directlyReachable [ 8098 ];
  };
}
