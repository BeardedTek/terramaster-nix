{ config, lib, ... }:

let
  lanIf = config.mySystem.lanInterface;

  # Base name -> local port. Router/service names for each are derived
  # below (e.g. "jellyfin" -> backend key "jellyfin-young", nebula domain
  # "jellyfin-young.nebula.beardedtek.com", LAN domain
  # "jellyfin.young.beardedtek.com").
  backends = {
    jellyfin = 8096;
    sonarr = 8989;
    radarr = 7878;
    jackett = 9117;
    seerr = 5055;
    qbittorrent = 8080;
    frigate = 8098; # modules/frigate.nix — nginx vhost fronting frigate, not frigate's raw process
    hass = 8123; # modules/home-assistant.nix
  };

  nebulaTls = {
    certResolver = "dns01-nebula";
    domains = [
      {
        main = "nebula.beardedtek.com";
        sans = [ "*.nebula.beardedtek.com" ];
      }
    ];
  };

  lanTls = {
    certResolver = "dns01-nebula";
    domains = [
      {
        main = "young.beardedtek.com";
        sans = [ "*.young.beardedtek.com" ];
      }
    ];
  };

  routersFor = name: extraMiddlewares: {
    "${name}-young-nebula" = {
      rule = "Host(`${name}-young.nebula.beardedtek.com`)";
      service = "${name}-young";
      entryPoints = [ "https" ];
      tls = nebulaTls;
    } // (lib.optionalAttrs (extraMiddlewares != [ ]) { middlewares = extraMiddlewares; });
    "${name}-young-lan" = {
      rule = "Host(`${name}.young.beardedtek.com`)";
      service = "${name}-young";
      entryPoints = [ "https" ];
      tls = lanTls;
    } // (lib.optionalAttrs (extraMiddlewares != [ ]) { middlewares = extraMiddlewares; });
  };
in
{
  # Reverse-proxies every backend behind two domain schemes at once —
  # matches the user's existing traefik:v3 docker-compose setup, translated
  # to the native `services.traefik` module (no docker socket/provider
  # here, so routing is static via dynamicConfigOptions instead of
  # container labels):
  #   - over Nebula:  <name>-young.nebula.beardedtek.com
  #   - over the LAN: <name>.young.beardedtek.com
  # DNS for both is managed outside this repo — Traefik only handles TLS
  # and routing once a request actually arrives.
  services.traefik = {
    enable = true;

    # LINODE_TOKEN for the DNS-01 challenge — out-of-repo secret, delivered
    # the same way as the Nebula config (see docs/DEPLOYMENT.md and
    # secrets/extra-files/persist/etc/traefik/traefik.env.example). Traefik's
    # lego/linode DNS provider reads LINODE_TOKEN straight from the process
    # environment, so no envsubst templating is needed in the static config
    # below — this just needs to be present in the unit's environment.
    environmentFiles = [ "/etc/traefik/traefik.env" ];

    # ReadWritePaths in the upstream module is just [ dataDir ] (ProtectSystem
    # = "full") — every writable path below (acme storage, logs) has to live
    # under /var/lib/traefik, not under a separate logs/ subdirectory that
    # nothing would create for us.
    staticConfigOptions = {
      api = {
        dashboard = true;
        insecure = true; # matches the original compose's --api.insecure=true
      };
      log = {
        level = "DEBUG";
        filePath = "/var/lib/traefik/traefik.log";
      };
      accessLog.filePath = "/var/lib/traefik/access.log";

      entryPoints = {
        # No IPs hardcoded here on purpose — bound to every interface,
        # same as every other service in this repo (Samba, NFS, SSH).
        # Actual reachability is controlled entirely by the per-interface
        # firewall rules below, which cover both the LAN and nebula1.
        traefik.address = ":8099"; # dashboard/API

        http = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "https";
            scheme = "https";
          };
        };

        https.address = ":443";
      };

      certificatesResolvers.dns01-nebula.acme = {
        dnsChallenge = {
          provider = "linode";
          resolvers = [ "92.123.94.2:53" "92.123.94.3:53" ];
        };
        email = "le@beardedtek.com";
        storage = "/var/lib/traefik/acme.json";
      };
    };

    # File-provider routing (providers.file.filename is wired automatically
    # by the traefik module itself from this attrset — no need to declare
    # providers.file ourselves). Two routers per backend (one per domain
    # scheme, each pinning its own wildcard cert's domains explicitly) —
    # entrypoint-level default tls.domains was tried first and does NOT
    # work: it only propagates as something routers *inherit*, it does not
    # by itself cause Traefik to proactively request a cert. Confirmed the
    # hard way (acme.json stayed empty, zero ACME log activity, even with
    # real traffic presenting the correct SNI) until explicit per-router
    # tls.domains was added — matching the original docker-compose's
    # proven-working "wildcard" router pattern.
    dynamicConfigOptions = {
      http.routers = (lib.foldl' (
        acc: name:
        acc // (routersFor name (lib.optionals (name == "qbittorrent") [ "qb-headers" ]))
      ) { } (builtins.attrNames backends)) // {
        # The NAS dashboard itself lives at the bare "young" host, not the
        # <name>-young/<name>.young pattern every other backend uses — it's
        # the box's own landing page, not one more proxied service.
        young-nebula = {
          rule = "Host(`young.nebula.beardedtek.com`)";
          service = "dashboard";
          entryPoints = [ "https" ];
          tls = nebulaTls;
        };
        young-lan = {
          rule = "Host(`young.beardedtek.com`)";
          service = "dashboard";
          entryPoints = [ "https" ];
          tls = lanTls;
        };
      };

      http.services = (lib.mapAttrs' (
        name: port:
        lib.nameValuePair "${name}-young" {
          loadBalancer.servers = [ { url = "http://127.0.0.1:${toString port}"; } ];
        }
      ) backends) // {
        dashboard.loadBalancer.servers = [ { url = "http://127.0.0.1:8097"; } ];
        # qBittorrent's WebUI validates the Host header against its own bind
        # address by default and rejects anything else with 401 — Traefik
        # normally forwards the real client-requested hostname through
        # (passHostHeader, true everywhere else), which is exactly what
        # trips that check. Rather than touch qBittorrent's own config to
        # work around it (its NixOS module fully overwrites qBittorrent.conf
        # on every restart once any serverConfig key is set, discarding
        # runtime changes like a WebUI password reset — confirmed the hard
        # way), just don't forward the real Host header for this one
        # service: qBittorrent then sees "Host: 127.0.0.1:8080", which its
        # validation already accepts natively.
        qbittorrent-young.loadBalancer = {
          servers = [ { url = "http://127.0.0.1:${toString backends.qbittorrent}"; } ];
          passHostHeader = false;
        };
      };

      # passHostHeader=false alone isn't enough for qBittorrent: it also
      # has a separate CSRF/cross-site check comparing Origin/Referer
      # against the Host header, and the browser's real Origin/Referer
      # still say the actual domain regardless of what Host Traefik
      # forwards — so the mismatch just moves from one check to the other,
      # still 401. Matches qBittorrent's own documented Traefik setup
      # (https://github.com/qbittorrent/qBittorrent/wiki/Traefik-Reverse-Proxy-for-Web-UI):
      # strip Origin/Referer entirely so there's nothing to mismatch.
      http.middlewares.qb-headers.headers.customRequestHeaders = {
        X-Frame-Options = "SAMEORIGIN";
        Referer = "";
        Origin = "";
      };
    };
  };

  networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 80 443 8099 ];
  networking.firewall.interfaces.${lanIf}.allowedTCPPorts = [ 80 443 8099 ];

  # Exposes `backends` (above) to other modules — modules/dashboard.nix
  # reads this for its per-service up/down checks, so there's one list of
  # services/ports instead of two copies drifting apart.
  mySystem.serviceBackends = backends;
}
