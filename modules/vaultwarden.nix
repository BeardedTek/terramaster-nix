{ config, lib, ... }:

let
  f = config.mySystem.features;
  hostName = config.networking.hostName;
  domain = config.mySystem.domain;
in
{
  config = lib.mkIf f.vaultwarden.enable {
    # ADMIN_TOKEN, delivered out-of-repo — see
    # secrets/extra-files/persist/etc/vaultwarden/admin.env.example.
    # Genuinely optional per Vaultwarden's own docs (no token = no
    # /admin panel, everything else still works) — but
    # services.vaultwarden.environmentFile only accepts a real Nix
    # `path`, which systemd's EnvironmentFile= then treats as
    # *mandatory* (a missing file fails the whole unit: "Failed to
    # load environment files", confirmed the hard way on young).
    # Setting the raw systemd option directly instead, with the "-"
    # prefix systemd's own EnvironmentFile= syntax uses for "load if
    # present, ignore if not," sidesteps that type restriction — NixOS
    # merges this with vaultwarden's own module-generated
    # serviceConfig.EnvironmentFile list rather than replacing it, so
    # the base env file it always writes still loads too.
    systemd.services.vaultwarden.serviceConfig.EnvironmentFile = [ "-/etc/vaultwarden/admin.env" ];

    services.vaultwarden = {
      enable = true;
      config = {
        # Loopback-only + fronted by the same shared Traefik backend
        # mechanism every other service here uses (modules/traefik.nix's
        # backends.vaultwarden) — no configureNginx/domain from this
        # module's own built-in nginx path, and no direct firewall port
        # either: Bitwarden clients connect via a configured server
        # *URL*, not a raw IP:port, so there's nothing for a direct port
        # to usefully serve here (same posture as the `auth` backend).
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        DOMAIN = "https://vaultwarden.${hostName}.${domain}";
        SIGNUPS_ALLOWED = f.vaultwarden.signupsAllowed;
        ENABLE_WEBSOCKET = true;
      };
    };
  };
}
