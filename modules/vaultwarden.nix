{ config, lib, ... }:

let
  f = config.mySystem.features;
  hostName = config.networking.hostName;
  domain = config.mySystem.domain;
in
{
  config = lib.mkIf f.vaultwarden.enable {
    services.vaultwarden = {
      enable = true;
      # ADMIN_TOKEN, delivered out-of-repo — see
      # secrets/extra-files/persist/etc/vaultwarden/admin.env.example.
      # Optional per Vaultwarden's own docs (no token = no /admin panel,
      # everything else still works), but nixpkgs' own option type only
      # accepts a real path here, not systemd's "-optional" EnvironmentFile
      # syntax, so a missing file is a clean no-start for this unit —
      # same posture as modules/minio.nix's rootCredentialsFile.
      environmentFile = "/etc/vaultwarden/admin.env";
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
