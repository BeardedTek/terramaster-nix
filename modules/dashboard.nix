{ config, lib, pkgs, ... }:

let
  lanIf = config.mySystem.lanInterface;
  hostName = config.networking.hostName;
  backends = config.mySystem.serviceBackends; # set by modules/traefik.nix
  f = config.mySystem.features;
  # nixpkgs' own default, but read from config rather than hardcoded so
  # this stays correct if modules/tailscale.nix ever overrides it.
  tsIf = config.services.tailscale.interfaceName;

  # See modules/dashboard-login.nix for the full rationale — a dashboard-
  # local LDAP-bind login rather than routing through Authelia, since
  # Authelia's session cookie can't work for this vhost's direct-IP
  # access path at all (domain-scoped cookies are never sent to a raw IP
  # request, by browsers, unconditionally). Off entirely (homepage and
  # everything else public, exactly as before this feature existed)
  # unless LLDAP itself is enabled.
  loginEnabled = config.mySystem.features.sso.enable;
  authRequestSnippet = ''
    auth_request /internal/dashboard-auth-check;
  '';

  # Generated from mySystem.contactInfo (set per-host, e.g.
  # hosts/terramaster/f4-245/configuration.nix) rather than hardcoded into the Hugo
  # content itself — Hugo auto-loads any data/*.json file as
  # .Site.Data.contact, read by dashboard/layouts/partials/contact-info.html
  # (shared by the footer and the Help page's {{< contact >}} shortcode).
  contactDataFile = pkgs.writeText "contact.json" (builtins.toJSON config.mySystem.contactInfo);

  # Same auto-loaded-by-Hugo shape as contact.json, read by
  # dashboard/layouts/index.html's Network section — which mesh VPN
  # cards to render is a build-time decision (whether the interface
  # exists at all), unlike each card's live up/down state, which stays
  # a runtime metrics.json concern (see net_json below). Regenerated on
  # every rebuild, so toggling Nebula/Tailscale off on the Services page
  # removes/adds the corresponding card the next time this rebuilds.
  networkInterfacesDataFile = pkgs.writeText "networkinterfaces.json" (builtins.toJSON (
    (lib.optional f.nebula.enable { iface = "nebula"; label = "Nebula"; })
    ++ (lib.optional f.tailscale.enable { iface = "tailscale"; label = "Tailscale"; })
    ++ [ { iface = "lan"; label = "Local Ethernet"; } ]
  ));

  # Built once at nixos-rebuild time from ../dashboard — the Hugo source
  # for this. No npm/webpack/Tailwind build here on purpose: the theme's
  # CSS/JS bundles are vendored pre-built into dashboard/static (see
  # docs/ARCHITECTURE.md) specifically to keep this a single lightweight
  # `hugo` invocation, nothing heavier.
  # dashboard/hugo.toml is committed with "young" (this repo's own
  # reference host) hardcoded as both the page title and params.hostname —
  # every layout (nav badge, footer, <title>, index heading) reads from
  # it. Without this override every host built from this repo shows
  # "young" in its own dashboard regardless of its real hostname, since
  # the file is never otherwise templated. Single source of truth stays
  # dashboard/hugo.toml; this just substitutes the one placeholder value
  # at build time rather than duplicating the whole file's contents here.
  hugoConfigFile = pkgs.writeText "hugo.toml" (
    lib.replaceStrings [ "young" ] [ hostName ] (builtins.readFile ../dashboard/hugo.toml)
  );

  dashboardSite = pkgs.stdenv.mkDerivation {
    pname = "${hostName}-dashboard";
    version = "1";
    src = ../dashboard;
    nativeBuildInputs = [ pkgs.hugo ];
    dontBuild = true;
    installPhase = ''
      mkdir -p data
      cp ${contactDataFile} data/contact.json
      cp ${networkInterfacesDataFile} data/networkinterfaces.json
      hugo --minify -d $out --config ${hugoConfigFile}
    '';
  };

  # Regenerates /var/lib/dashboard/metrics.json every 30s (matching the
  # dashboard page's own JS poll interval) — deliberately just a few `df`/
  # `/proc` reads and a jq call, not a metrics agent/exporter/database.
  # Never persisted across reboots on purpose: it's fully regenerated
  # within 30s of boot, so there's nothing worth carrying over the tmpfs
  # root, and one less thing in environment.persistence to get wrong.
  metricsScript = pkgs.writeShellApplication {
    name = "dashboard-metrics";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.iproute2 pkgs.gawk pkgs.iputils pkgs.netcat pkgs.tailscale ];
    text = ''
      out=/var/lib/dashboard/metrics.json
      tmp=$(mktemp)

      disk_json() {
        local path="$1" name="$2"
        read -r used avail size pcent < <(df -B1 --output=used,avail,size,pcent "$path" | tail -n1 | tr -d '%')
        jq -n --arg name "$name" \
              --arg used "$(numfmt --to=iec --suffix=B "$used")" \
              --arg avail "$(numfmt --to=iec --suffix=B "$avail")" \
              --arg total "$(numfmt --to=iec --suffix=B "$size")" \
              --argjson pct "$pcent" \
              '{name:$name, used:$used, avail:$avail, total:$total, pct:$pct}'
      }
      disks=$(jq -s '.' \
        <(disk_json /rust rust) \
        <(disk_json /rust/media rust/media) \
        <(disk_json /rust/data rust/data))

      read -r one five fifteen _ < /proc/loadavg
      load=$(jq -n --arg one "$one" --arg five "$five" --arg fifteen "$fifteen" \
        '{one:$one, five:$five, fifteen:$fifteen}')

      mem_total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
      mem_avail_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
      mem_used_kb=$((mem_total_kb - mem_avail_kb))
      mem_pct=$((mem_used_kb * 100 / mem_total_kb))
      memory=$(jq -n \
        --arg used "$(numfmt --to=iec --suffix=B $((mem_used_kb * 1024)))" \
        --arg total "$(numfmt --to=iec --suffix=B $((mem_total_kb * 1024)))" \
        --argjson pct "$mem_pct" \
        '{used:$used, total:$total, pct:$pct}')

      # $3, if given, is either a host to ping or the literal string
      # "backendstate" to determine "up" instead of trusting operstate.
      # Needed for nebula1/tailscale0 specifically: TUN/overlay
      # interfaces have no physical carrier to detect, so the kernel
      # reports operstate "unknown" even when the tunnel is working fine
      # — confirmed the hard way, the dashboard showed Nebula as
      # permanently "down" despite it working. Physical ethernet (lan)
      # doesn't have this problem, so it keeps using the cheaper
      # operstate check. Nebula pings its lighthouse (a fixed, known-at-
      # build-time IP); Tailscale has no equivalent fixed peer to ping,
      # so it instead asks tailscaled's own `status --json` for
      # BackendState — "Running" is the same definition of "connected"
      # modules/dashboard-tailscale.nix's currentCgi already uses.
      # Tradeoff: this makes Nebula's status depend on one specific peer
      # (the lighthouse) being reachable, not just the tunnel itself.
      net_json() {
        local iface="$1" label="$2" mode="''${3:-}" up="false" ip=""
        if [ -e "/sys/class/net/$iface" ]; then
          ip=$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
          if [ "$mode" = "backendstate" ]; then
            # writeShellApplication's errexit+pipefail would otherwise
            # abort this whole script (30s-timer-driven, so a crash
            # here would silently stop updating every other card too)
            # the moment tailscaled isn't reachable — same guard shape
            # as modules/dashboard-tailscale.nix's currentCgi.
            raw=$(tailscale status --json 2>/dev/null) || raw=""
            state=""
            if [ -n "$raw" ]; then
              state=$(printf '%s' "$raw" | jq -r '.BackendState // empty' 2>/dev/null || true)
            fi
            [ "$state" = "Running" ] && up="true"
          elif [ -n "$mode" ]; then
            ping -c1 -W1 "$mode" >/dev/null 2>&1 && up="true"
          else
            state=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null || echo down)
            [ "$state" = "up" ] && up="true"
          fi
        fi
        jq -n --arg iface "$label" --argjson up "$up" --arg ip "''${ip:-}" \
          '{iface:$iface, up:$up, ip:$ip}'
      }
      network=$(jq -s '.' \
        ${lib.concatStringsSep " \\\n        " (
          (lib.optional f.nebula.enable "<(net_json nebula1 nebula 10.100.0.1)")
          ++ (lib.optional f.tailscale.enable "<(net_json ${tsIf} tailscale backendstate)")
          ++ [ "<(net_json \"${lanIf}\" lan)" ]
        )})

      # Plain TCP connect check against each backend's local port (from
      # mySystem.serviceBackends, set once in modules/traefik.nix — not
      # duplicated here) — enough to answer "is this reachable at all",
      # without an HTTP request/parsing per service. Uses `nc -z` rather
      # than bash's /dev/tcp redirection — confirmed the hard way that
      # nixpkgs' non-interactive bash build can't be relied on to have
      # /dev/tcp net-redirection support compiled in: the check ran with
      # no errors (exit 0) but never actually connected to anything (the
      # service's own IPAccounting showed ~84B total traffic for six
      # supposed connection attempts — consistent with none of them ever
      # really happening).
      service_json() {
        local name="$1" port="$2" up="false"
        nc -z -w2 127.0.0.1 "$port" >/dev/null 2>&1 && up="true"
        jq -n --arg name "$name" --argjson up "$up" --argjson port "$port" \
          '{name:$name, up:$up, port:$port}'
      }
      services=$(jq -s '.' \
        ${lib.concatStringsSep " \\\n        " (
          lib.mapAttrsToList (name: port: "<(service_json ${name} ${toString port})") backends
        )})

      jq -n --arg generated_at "$(date -Is)" \
            --arg host "${hostName}" \
            --argjson disks "$disks" \
            --argjson load "$load" \
            --argjson memory "$memory" \
            --argjson network "$network" \
            --argjson services "$services" \
            '{generated_at:$generated_at, host:$host, disks:$disks, load:$load, memory:$memory, network:$network, services:$services}' \
            > "$tmp"

      chmod 644 "$tmp"
      mv "$tmp" "$out"
    '';
  };
in
{
  systemd.services.dashboard-metrics = {
    description = "Regenerate the NAS dashboard's metrics.json";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${metricsScript}/bin/dashboard-metrics";
      StateDirectory = "dashboard";
      StateDirectoryMode = "0755";
    };
  };

  systemd.timers.dashboard-metrics = {
    description = "Run dashboard-metrics every 30s";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5s";
      OnUnitActiveSec = "30s";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts.dashboard = {
      serverName = "_";
      listen = [
        { addr = "0.0.0.0"; port = 8097; }
        { addr = "[::]"; port = 8097; }
      ];
      root = dashboardSite;
      # nginx builds an absolute URL for any bare-path `return`/redirect
      # (including modules/dashboard-login.nix's @dashboard_login_redirect
      # below) from its own view of scheme/host/port by default — since
      # Traefik proxies HTTPS on 443 to this vhost's plain-HTTP internal
      # listener on 8097, that produces a Location header pointing at
      # http://<host>:8097/login/, which browsers then block as mixed
      # content on an HTTPS page. Confirmed live via Chrome DevTools:
      # every gated static asset (e.g. favicon.ico/.svg, which aren't in
      # the public locations list below) 401'd, then failed exactly this
      # way. `absolute_redirect off` makes nginx emit just the relative
      # path instead, which the browser correctly resolves against
      # whatever origin it's actually on.
      extraConfig = ''
        absolute_redirect off;
      '' + lib.optionalString loginEnabled ''
        error_page 401 = @dashboard_login_redirect;
      '';
      locations = {
        # Public, same as the homepage itself — the homepage's own live
        # status widgets (disk/load/memory/network/service reachability)
        # read this, and the homepage is meant to be viewable without
        # logging in at all.
        "= /metrics.json" = {
          alias = "/var/lib/dashboard/metrics.json";
        };

        # Explicit exact match — takes precedence over the general "/"
        # fallback below for just the root path, keeping the homepage
        # public even though everything else requires login. try_files
        # (rather than relying on the default `index` directive) matters
        # here: nginx's `index` resolves a directory request via an
        # *internal redirect* to /index.html, which re-runs location
        # matching from scratch — and /index.html doesn't match this
        # exact "= /" block, so it fell through to the general "/"
        # location below and got gated anyway (confirmed live: curl
        # against "/" 302'd to /login/ despite this block existing).
        # try_files serves the file within this same location's context,
        # no re-match, so it actually stays public.
        "= /" = {
          root = dashboardSite;
          extraConfig = ''
            try_files /index.html =404;
          '';
        };
      } // (lib.optionalAttrs loginEnabled {
        # Static assets the public homepage (and modules/dashboard-login.nix's
        # login page) need to render — kept public regardless of login
        # state, same reasoning as the homepage itself. The login page's
        # own location (/login/) and CGI endpoints
        # (/login/submit, /logout, the internal auth-check location, and
        # the @dashboard_login_redirect the error_page above points at)
        # live in modules/dashboard-login.nix, alongside the CGI
        # derivations they reference — same file, same "one module owns
        # its own nginx locations" shape modules/self-update.nix already
        # uses for /update/status and /update/trigger on this same vhost.
        "^~ /css/".root = dashboardSite;
        "^~ /js/".root = dashboardSite;
        "^~ /images/".root = dashboardSite;

        # LLDAP's own admin UI redirect page — public for the same reason
        # /login/ is: someone locked out (forgotten password) needs to be
        # able to reach LLDAP to reset it without already being logged
        # into the dashboard first.
        "^~ /account/".root = dashboardSite;

        # Catch-all: every other dashboard page (Services, Samba, NFS,
        # the /update page, Help) falls through to here and requires
        # login. Explicit root, not relying on inheritance from the
        # vhost level, to keep this location's behavior fully spelled
        # out alongside the auth_request that makes it different from
        # the equivalent unauthenticated default this repo had before.
        "/" = {
          root = dashboardSite;
          extraConfig = authRequestSnippet;
        };
      });
    };
  };

  networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 8097 ];
  networking.firewall.interfaces.${lanIf}.allowedTCPPorts = [ 8097 ];

  mySystem.dashboardSite = dashboardSite;
}
