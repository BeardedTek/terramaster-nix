{ config, lib, ... }:

let
  hostName = config.networking.hostName;
in
{
  services.samba = {
    enable = true;
    settings = {
      global = {
        workgroup = lib.toUpper hostName;
        "server string" = hostName;
        "netbios name" = hostName;
        security = "user";
        "server min protocol" = "SMB2";
        "map to guest" = "never";
      };

      media = {
        path = "/rust/media";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "beardedtek dyoung";
        "admin users" = "beardedtek";
      };

      data = {
        path = "/rust/data";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "beardedtek dyoung";
        "admin users" = "beardedtek";
      };
    } // lib.optionalAttrs config.mySystem.features.homeAssistant.enable {
      hass = {
        path = "/var/lib/hass";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "beardedtek dyoung";
        "admin users" = "beardedtek";
        "force user" = "hass";
        "force group" = "hass";
      };
    };
  };

  networking.firewall.interfaces.${config.mySystem.lanInterface}.allowedTCPPorts = [ 445 ];
  networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 445 ];
}
