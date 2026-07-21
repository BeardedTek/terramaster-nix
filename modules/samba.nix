{ config, ... }:

{
  services.samba = {
    enable = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "young";
        "netbios name" = "young";
        security = "user";
        # Both stated clients (a current macOS and a current Android) are
        # SMB3-capable, so no need for legacy SMB1/NTLM compatibility.
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

  # Scoped open, not a blanket `openFirewall` — restrict Samba to the LAN
  # and the Nebula mesh only. See mySystem.lanInterface (modules/common.nix)
  # for the one place that name is set.
  networking.firewall.interfaces.${config.mySystem.lanInterface}.allowedTCPPorts = [ 445 ];
  networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 445 ];

  # Samba passwords are a separate database from Unix login passwords and
  # aren't declarative here — after first deploy, run once for each user:
  #   sudo smbpasswd -a beardedtek
  #   sudo smbpasswd -a dyoung
}
