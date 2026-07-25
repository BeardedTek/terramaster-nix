{ config, lib, ... }:

let
  lanIf = config.mySystem.lanInterface;
  hostName = config.networking.hostName;
  f = config.mySystem.features;

  backends = {
    jellyfin = 8096;
    sonarr = 8989;
    radarr = 7878;
    jackett = 9117;
    seerr = 5055;
    qbittorrent = 8080;
    frigate = 8098;
    hass = 8123;
  };

  backendEnabled = {
    jellyfin = f.jellyfin.enable;
    frigate = f.frigate.enable;
    hass = f.homeAssistant.enable;
    sonarr = f.mediaAcquisition.enable && f.mediaAcquisition.sonarr.enable;
    radarr = f.mediaAcquisition.enable && f.mediaAcquisition.radarr.enable;
    jackett = f.mediaAcquisition.enable && f.mediaAcquisition.jackett.enable;
    seerr = f.mediaAcquisition.enable && f.mediaAcquisition.seerr.enable;
    qbittorrent = f.mediaAcquisition.enable && f.mediaAcquisition.qbittorrent.enable;
  };

  enabledBackends = lib.filterAttrs (name: _: backendEnabled.${name}) backends;

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
        main = "${hostName}.beardedtek.com";
        sans = [ "*.${hostName}.beardedtek.com" ];
      }
    ];
  };

  routersFor = name: extraMiddlewares: {
    "${name}-${hostName}-nebula" = {
      rule = "Host(`${name}-${hostName}.nebula.beardedtek.com`)";
      service = "${name}-${hostName}";
      entryPoints = [ "https" ];
      tls = nebulaTls;
    } // (lib.optionalAttrs (extraMiddlewares != [ ]) { middlewares = extraMiddlewares; });
    "${name}-${hostName}-lan" = {
      rule = "Host(`${name}.${hostName}.beardedtek.com`)";
      service = "${name}-${hostName}";
      entryPoints = [ "https" ];
      tls = lanTls;
    } // (lib.optionalAttrs (extraMiddlewares != [ ]) { middlewares = extraMiddlewares; });
  };
in
{
  services.traefik = {
    enable = true;
    environmentFiles = [ "/etc/traefik/traefik.env" ];

    staticConfigOptions = {
      api = {
        dashboard = true;
        insecure = true;
      };
      log = {
        level = "DEBUG";
        filePath = "/var/lib/traefik/traefik.log";
      };
      accessLog.filePath = "/var/lib/traefik/access.log";

      entryPoints = {
        traefik.address = ":8099";

        http = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "https";
            scheme = "https";
          };
        };

        https.address = ":443";

        lan-local.address = ":8090";
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

    dynamicConfigOptions = {
      http.routers = (lib.foldl' (
        acc: name:
        acc // (routersFor name (lib.optionals (name == "qbittorrent") [ "qb-headers" ]))
      ) { } (builtins.attrNames enabledBackends)) // {
        "${hostName}-nebula" = {
          rule = "Host(`${hostName}.nebula.beardedtek.com`)";
          service = "dashboard";
          entryPoints = [ "https" ];
          tls = nebulaTls;
        };
        "${hostName}-lan" = {
          rule = "Host(`${hostName}.beardedtek.com`)";
          service = "dashboard";
          entryPoints = [ "https" ];
          tls = lanTls;
        };
      } // {
        local-dashboard = {
          rule = "PathPrefix(`/`)";
          service = "dashboard";
          entryPoints = [ "lan-local" ];
        };
      };

      http.services = (lib.mapAttrs' (
        name: port:
        lib.nameValuePair "${name}-${hostName}" {
          loadBalancer.servers = [ { url = "http://127.0.0.1:${toString port}"; } ];
        }
      ) enabledBackends) // {
        dashboard.loadBalancer.servers = [ { url = "http://127.0.0.1:8097"; } ];
      } // (lib.optionalAttrs (enabledBackends ? qbittorrent) {
        "qbittorrent-${hostName}".loadBalancer = {
          servers = [ { url = "http://127.0.0.1:${toString backends.qbittorrent}"; } ];
          passHostHeader = false;
        };
      });

      http.middlewares.qb-headers.headers.customRequestHeaders = {
        X-Frame-Options = "SAMEORIGIN";
        Referer = "";
        Origin = "";
      };
    };
  };

  networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 80 443 8099 ];
  networking.firewall.interfaces.${lanIf}.allowedTCPPorts = [ 80 443 8099 8090 ];

  mySystem.serviceBackends = enabledBackends;
}
