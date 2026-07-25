{ config, lib, ... }:

let
  hostName = config.networking.hostName;
  vhost = "frigate.${hostName}.beardedtek.com";
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
      serverAliases = [ "frigate-${hostName}.nebula.beardedtek.com" ];
    };

    networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 8098 ];
    networking.firewall.interfaces.${config.mySystem.lanInterface}.allowedTCPPorts = [ 8098 ];
  };
}
