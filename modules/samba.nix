{ config, lib, ... }:

let
  hostName = config.networking.hostName;

  # mySystem.users is the single source of truth for who has an account on
  # this box (modules/users.nix provisions the matching Unix account,
  # modules/lldap.nix mirrors the same list into LLDAP) — deriving Samba's
  # user lists from it here too means adding someone in one place is
  # enough, instead of hand-editing this hardcoded string on every share.
  # Samba itself still authenticates against its own separate tdbsam
  # password (set via `smbpasswd`, not LLDAP — see
  # docs/content/en/docs/usage/services/samba/_index.md), so a name here
  # is meaningless until both a real Unix account exists (mySystem.users)
  # and `smbpasswd -a <name>` has been run for them.
  validUsers = lib.concatMapStringsSep " " (u: u.name) config.mySystem.users;
  adminUsers = lib.concatMapStringsSep " " (u: u.name) (lib.filter (u: u.wheel) config.mySystem.users);
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
        "valid users" = validUsers;
        "admin users" = adminUsers;
      };

      data = {
        path = "/rust/data";
        browseable = "yes";
        "read only" = "no";
        "valid users" = validUsers;
        "admin users" = adminUsers;
      };
    } // lib.optionalAttrs config.mySystem.features.homeAssistant.enable {
      hass = {
        path = "/var/lib/hass";
        browseable = "yes";
        "read only" = "no";
        "valid users" = validUsers;
        "admin users" = adminUsers;
        "force user" = "hass";
        "force group" = "hass";
      };
    };
  };

  networking.firewall.interfaces.${config.mySystem.lanInterface}.allowedTCPPorts = [ 445 ];
  networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 445 ];
}
