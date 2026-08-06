{ config, lib, ... }:

let
  lanIf = config.mySystem.lanInterface;
  hostName = config.networking.hostName;
  domain = config.mySystem.domain;
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
    minio = 9000;
    "minio-console" = 9001;
    files = 8095;
    # "auth", not "authelia": modules/authelia.nix's own
    # session.cookies[0].authelia_url points at auth.${hostName}.${domain}
    # (confirmed the hard way — a mismatched name here means Authelia
    # redirects unauthenticated requests to a hostname with no router at
    # all). Keep the two in sync if either changes.
    auth = 9091;
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
    minio = f.minio.enable;
    "minio-console" = f.minio.enable;
    files = f.filebrowser.enable;
    auth = f.sso.authelia.enable;
  };

  enabledBackends = lib.filterAttrs (name: _: backendEnabled.${name}) backends;

  # Set by modules/authelia.nix; read here to decide which backends get
  # the `authelia` ForwardAuth middleware attached below — same
  # "one file computes, another consumes" shape mySystem.serviceBackends
  # already uses between this file and modules/dashboard.nix.
  protected = config.mySystem.sso.protectedServices;

  nebulaTls = {
    certResolver = "dns01-nebula";
    domains = [
      {
        main = "nebula.${domain}";
        sans = [ "*.nebula.${domain}" ];
      }
    ];
  };

  lanTls = {
    certResolver = "dns01-nebula";
    domains = [
      {
        main = "${hostName}.${domain}";
        sans = [ "*.${hostName}.${domain}" ];
      }
    ];
  };

  routersFor = name: extraMiddlewares: {
    "${name}-${hostName}-nebula" = {
      rule = "Host(`${name}-${hostName}.nebula.${domain}`)";
      service = "${name}-${hostName}";
      entryPoints = [ "https" ];
      tls = nebulaTls;
    } // (lib.optionalAttrs (extraMiddlewares != [ ]) { middlewares = extraMiddlewares; });
    "${name}-${hostName}-lan" = {
      rule = "Host(`${name}.${hostName}.${domain}`)";
      service = "${name}-${hostName}";
      entryPoints = [ "https" ];
      tls = lanTls;
    } // (lib.optionalAttrs (extraMiddlewares != [ ]) { middlewares = extraMiddlewares; });
  };
in
{
  services.traefik = {
    enable = true;
    # Kept as a real (non-"-") path here: services.traefik.environmentFiles
    # is typed `listOf path`, which rejects a "-"-prefixed string outright
    # ("is not of type absolute path") — confirmed the hard way. This value
    # still needs to be non-empty regardless, since nixpkgs' own module
    # uses `cfg.environmentFiles != []` to decide whether to route through
    # the envsubst'd /run/traefik/config.toml at all (see
    # systemd.services.traefik override below, which makes the file
    # optional at the *systemd* level instead).
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
        acc // (routersFor name (
          (lib.optionals (name == "qbittorrent") [ "qb-headers" ])
          ++ (lib.optionals (protected ? ${name}) [ "authelia" ])
          ++ (lib.optionals (name == "frigate" && protected ? frigate) [ "frigate-proxy-secret" ])
        ))
      ) { } (builtins.attrNames enabledBackends)) // {
        "${hostName}-nebula" = {
          rule = "Host(`${hostName}.nebula.${domain}`)";
          service = "dashboard";
          entryPoints = [ "https" ];
          tls = nebulaTls;
        };
        "${hostName}-lan" = {
          rule = "Host(`${hostName}.${domain}`)";
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

      http.middlewares = {
        qb-headers.headers.customRequestHeaders = {
          X-Frame-Options = "SAMEORIGIN";
          Referer = "";
          Origin = "";
        };
      } // (lib.optionalAttrs f.sso.authelia.enable {
        authelia.forwardAuth = {
          # Authelia 4.38+'s ForwardAuth endpoint (confirmed against the
          # 4.39.20 package this flake's nixpkgs pin — nixos-26.05 —
          # actually ships); older Authelia used /api/verify instead.
          address = "http://127.0.0.1:${toString backends.auth}/api/authz/forward-auth";
          trustForwardHeader = true;
          authResponseHeaders = [ "Remote-User" "Remote-Groups" "Remote-Name" "Remote-Email" ];
        };
      }) // (lib.optionalAttrs (protected ? frigate) {
        # Frigate's own docs: without this, anything that can reach its
        # nginx vhost at all (not just Traefik) could forge
        # Remote-User/Remote-Groups and get in — Frigate checks this
        # header against its own settings.proxy.auth_secret
        # (modules/frigate.nix), which must be the exact same value.
        frigate-proxy-secret.headers.customRequestHeaders."X-Proxy-Secret" =
          lib.removeSuffix "\n" (builtins.readFile "/persist/etc/frigate/proxy_auth_secret");
      });
    };
  };

  # Overrides nixpkgs' own systemd.services.traefik.serviceConfig.EnvironmentFile
  # (set verbatim from services.traefik.environmentFiles above) with a
  # "-"-prefixed path — systemd's own EnvironmentFile= syntax for "load if
  # present, don't fail the unit if it's missing" — bypassing that NixOS
  # option's strict `listOf path` type (which rejects a "-" prefix outright)
  # by setting the underlying systemd directive directly instead. Matches
  # 70-secrets.sh's own documented intent ("Nebula/Traefik secrets are
  # optional — those services just won't work until configured
  # post-install"), which wasn't actually true before this: Traefik
  # (fronting every other web service on the box) failed to start at all
  # without a real LINODE_TOKEN, confirmed on a fresh install with no
  # DNS/ACME set up yet. The envsubst pre-start step (nixpkgs' own
  # traefik.nix) doesn't independently require the file to exist — it just
  # substitutes empty values for whatever didn't load — so this is safe:
  # cert issuance still fails without a real token, but Traefik itself (and
  # everything behind it) is reachable over plain HTTP either way.
  systemd.services.traefik.serviceConfig.EnvironmentFile =
    lib.mkForce "-/etc/traefik/traefik.env";

  networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 80 443 8099 ];
  networking.firewall.interfaces.${lanIf}.allowedTCPPorts = [ 80 443 8099 8090 ];

  mySystem.serviceBackends = enabledBackends;
}
