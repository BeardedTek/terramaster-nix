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

      # modules/home-assistant.nix's config dir (/var/lib/hass, owned by
      # the "hass" system user) — "force user"/"force group" so file
      # operations through this share happen as "hass" regardless of
      # which Samba user connected, rather than needing beardedtek/dyoung
      # added to that system user's group just to edit configuration.yaml
      # from a PC.
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
