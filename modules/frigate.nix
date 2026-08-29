{ config, lib, ... }:

let
  hostName = config.networking.hostName;
  domain = config.mySystem.domain;
  vhost = "frigate.${hostName}.${domain}";

  # Confirmed straight from Frigate's own maintainer (GitHub discussion
  # #19037): no native OIDC planned, "proxy" auth (trusting headers from
  # an already-authenticating reverse proxy) is the explicitly
  # recommended path for exactly this kind of setup.
  ssoEnabled = config.mySystem.sso.protectedServices ? frigate;

  # Only open Frigate's own port directly when it isn't SSO-gated —
  # otherwise http://<ip>:8098 bypasses Authelia's ForwardAuth middleware
  # entirely (Traefik/Authelia never see the request; nginx here is
  # listening on all interfaces regardless, so the firewall is the only
  # thing actually controlling reachability). See modules/media-stack.nix
  # for the same pattern applied to the media-acquisition services.
  directlyReachable = !ssoEnabled;

  # Checked against an X-Proxy-Secret header Traefik must send on every
  # request (modules/traefik.nix's frigate-proxy-secret middleware) —
  # Frigate's own docs: "If not set, all requests are trusted regardless
  # of origin," i.e. without this, anything that can reach Frigate's
  # nginx vhost at all could forge Remote-User/Remote-Groups headers
  # directly. Read straight from /persist (not /etc/frigate — no
  # impermanence bind-mount involved, sidesteps any first-boot
  # bind-mount-timing question entirely) and shared verbatim with
  # traefik.nix's copy; both must send/expect the exact same value.
  # Only ever forced (and so only ever needs to exist) once frigate is
  # actually in mySystem.sso.protectedServices, thanks to Nix's laziness.
  proxyAuthSecret = lib.removeSuffix "\n" (builtins.readFile "/persist/etc/frigate/proxy_auth_secret");
in
{
  config = lib.mkIf config.mySystem.features.frigate.enable {
    services.frigate = {
      enable = true;
      hostname = vhost;
      settings = {
        cameras = { };
        detectors.cpu1.type = "cpu";
      } // lib.optionalAttrs ssoEnabled {
        auth.enabled = false;
        proxy = {
          header_map = {
            user = "remote-user";
            role = "remote-groups";
            # Matches the "admins" LLDAP group modules/lldap.nix's
            # provisioning creates (wheel = true in mySystem.users) —
            # anyone else authenticated falls through to default_role.
            role_map.admin = [ "admins" ];
          };
          auth_secret = proxyAuthSecret;
          default_role = "viewer";
        };
      };
    };

    services.nginx.virtualHosts.${vhost} = {
      listen = [
        { addr = "0.0.0.0"; port = 8098; }
        { addr = "[::]"; port = 8098; }
      ];
      serverAliases = [ "frigate.${hostName}.nebula.${domain}" ];
    };

    networking.firewall.interfaces."nebula1".allowedTCPPorts = lib.optionals directlyReachable [ 8098 ];
    networking.firewall.interfaces.${config.mySystem.lanInterface}.allowedTCPPorts = lib.optionals directlyReachable [ 8098 ];
  };
}
