{ ... }:

{
  services.traefik = {
    enable = true;

    environmentFiles = [ "/etc/traefik/traefik.env" ];

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
        traefik.address = "10.100.0.17:8099";

        http = {
          address = "10.100.0.17:80";
          http.redirections.entryPoint = {
            to = "https";
            scheme = "https";
          };
        };

        https = {
          address = "10.100.0.17:443";
          http.tls = {
            certResolver = "dns01-nebula";
            domains = [
              {
                main = "nebula.beardedtek.com";
                sans = [ "*.nebula.beardedtek.com" ];
              }
            ];
          };
        };
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

    dynamicConfigOptions =
      let
        # Entrypoint-level tls.domains/certResolver only propagates as a
        # default for routers to *inherit* — it does not, by itself, cause
        # Traefik to proactively request the cert at startup. Confirmed the
        # hard way: acme.json stayed empty and traefik.log showed zero ACME
        # activity indefinitely, even with real traffic presenting the
        # correct SNI. Explicit per-router tls.domains (matching the
        # original docker-compose's proven-working "wildcard" router
        # pattern) is what actually triggers acquisition.
        wildcardTls = {
          certResolver = "dns01-nebula";
          domains = [
            {
              main = "nebula.beardedtek.com";
              sans = [ "*.nebula.beardedtek.com" ];
            }
          ];
        };
      in
      {
        http.routers = {
          jellyfin-young = {
            rule = "Host(`jellyfin-young.nebula.beardedtek.com`)";
            service = "jellyfin-young";
            entryPoints = [ "https" ];
            tls = wildcardTls;
          };
          sonarr-young = {
            rule = "Host(`sonarr-young.nebula.beardedtek.com`)";
            service = "sonarr-young";
            entryPoints = [ "https" ];
            tls = wildcardTls;
          };
          radarr-young = {
            rule = "Host(`radarr-young.nebula.beardedtek.com`)";
            service = "radarr-young";
            entryPoints = [ "https" ];
            tls = wildcardTls;
          };
          jackett-young = {
            rule = "Host(`jackett-young.nebula.beardedtek.com`)";
            service = "jackett-young";
            entryPoints = [ "https" ];
            tls = wildcardTls;
          };
          seerr-young = {
            rule = "Host(`seerr-young.nebula.beardedtek.com`)";
            service = "seerr-young";
            entryPoints = [ "https" ];
            tls = wildcardTls;
          };
          qbittorrent-young = {
            rule = "Host(`qbittorrent-young.nebula.beardedtek.com`)";
            service = "qbittorrent-young";
            entryPoints = [ "https" ];
            tls = wildcardTls;
          };
        };

        http.services = {
          jellyfin-young.loadBalancer.servers = [{ url = "http://127.0.0.1:8096"; }];
          sonarr-young.loadBalancer.servers = [{ url = "http://127.0.0.1:8989"; }];
          radarr-young.loadBalancer.servers = [{ url = "http://127.0.0.1:7878"; }];
          jackett-young.loadBalancer.servers = [{ url = "http://127.0.0.1:9117"; }];
          seerr-young.loadBalancer.servers = [{ url = "http://127.0.0.1:5055"; }];
          qbittorrent-young.loadBalancer.servers = [{ url = "http://127.0.0.1:8080"; }];
        };
      };
  };
  networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 80 443 8099 ];
}
