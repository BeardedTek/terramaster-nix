{ config, ... }:

{
  services.samba = {
    enable = true;
    settings = {
      global = {
        workgroup = "YOUNG";
        "server string" = "young";
        "netbios name" = "young";
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
    };
  };

  networking.firewall.interfaces.${config.mySystem.lanInterface}.allowedTCPPorts = [ 445 ];
  networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 445 ];
}
