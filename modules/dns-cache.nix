{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.dnsCache;
  lanIf = config.mySystem.lanInterface;
  hostName = config.networking.hostName;
  domain = config.mySystem.domain;

  # NOT 3000 — that's already modules/traefik.nix's "immich-share"
  # backend port; colliding here wouldn't be a Nix eval error (different
  # attrset keys) but a real runtime port-bind conflict between the two
  # actual processes if both features are ever enabled on the same host.
  webPort = 3080;
  dnsPort = 53;

  # Persisted under the same tmpfs-root + /persist bind-mount pattern
  # every other feature module uses (see hosts/*/configuration.nix's
  # environment.persistence."/persist".directories — "/etc/adguardhome"
  # needs adding there the same way "/etc/filebrowser" already is).
  # AdGuard Home's OWN state (users, blocklists, everything set through
  # its web UI) lives separately under /var/lib/private/AdGuardHome —
  # services.adguardhome runs with DynamicUser = true (confirmed against
  # nixpkgs' own module source), so that's already covered by the
  # existing blanket "/var/lib/private" entry every host already
  # persists for LLDAP/Scrutiny, no new entry needed for it.
  credsFile = "/etc/adguardhome/admin.env";
  bootstrapMarker = "/etc/adguardhome/.bootstrapped";
  managedRewritesFile = "/etc/adguardhome/managed-rewrites.json";

  # The exact same live attrset modules/traefik.nix's own routers are
  # generated from (mySystem.serviceBackends) — reused rather than
  # duplicated, so "this NAS's own service hostnames" always matches
  # whatever's actually enabled, with zero manual entry. Baked into the
  # generated reconcileScript below at Nix-eval time (not discovered at
  # runtime) — the ordinary "unit definition changed -> systemd restarts
  # it" activation behavior is what makes this stay in sync on every
  # rebuild, not any special path-triggering.
  wantedDomains = map (name: "${name}.${hostName}.${domain}") (lib.attrNames config.mySystem.serviceBackends);
  wantedDomainsJson = builtins.toJSON wantedDomains;

  # Completes AdGuard Home's own first-run setup wizard via its install
  # API instead of a human clicking through it — same "no manual
  # first-boot step" posture as filebrowser-setup.service's own admin
  # bootstrap. Deliberately does NOT declare `users` in
  # services.adguardhome.settings below — see that option's own comment
  # for why (mutableSettings' merge overwrites declared keys on *every*
  # restart, not just the first, which would silently revert any
  # password change made through AGH's own UI on the next rebuild).
  # Guarded on bootstrapMarker so this only ever runs once per box.
  bootstrapScript = pkgs.writeShellApplication {
    name = "dns-cache-bootstrap";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.coreutils pkgs.openssl ];
    text = ''
      if [ -f ${bootstrapMarker} ]; then
        exit 0
      fi
      mkdir -p "$(dirname ${credsFile})"

      # Wait for AdGuard Home's HTTP server to actually be listening —
      # only matters on a genuinely fresh /var/lib/private/AdGuardHome.
      waited=0
      until curl -fsS -o /dev/null "http://127.0.0.1:${toString webPort}/control/install/get_addresses" 2>/dev/null; do
        waited=$((waited + 1))
        [ "$waited" -ge 60 ] && break
        sleep 1
      done

      # 403 here means setup already completed out-of-band (e.g. a human
      # clicked through AGH's own wizard manually before this ran) —
      # nothing to do except record that and stop, never overwriting
      # whatever credentials already exist.
      status=$(curl -fsS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${toString webPort}/control/install/get_addresses" 2>/dev/null || echo 000)
      if [ "$status" = "403" ]; then
        touch ${bootstrapMarker}
        exit 0
      fi

      password=$(openssl rand -hex 16)
      body=$(jq -n --arg u admin --arg p "$password" \
        --argjson webport ${toString webPort} --argjson dnsport ${toString dnsPort} \
        '{web:{ip:"127.0.0.1",port:$webport}, dns:{ip:"0.0.0.0",port:$dnsport}, username:$u, password:$p, language:"en"}')
      curl -fsS -X POST "http://127.0.0.1:${toString webPort}/control/install/configure" \
        -H 'Content-Type: application/json' -d "$body" >/dev/null

      {
        echo "DNS_CACHE_ADMIN_USER=admin"
        echo "DNS_CACHE_ADMIN_PASSWORD=$password"
      } > ${credsFile}
      chmod 600 ${credsFile}
      touch ${bootstrapMarker}
    '';
  };

  # Adds/removes local DNS rewrites for exactly this NAS's own enabled
  # Traefik hostnames via AdGuard Home's REST API (never touches
  # services.adguardhome.settings — same reasoning as bootstrapScript).
  # Tracks which domains IT manages in managedRewritesFile so it only
  # ever adds/removes within that set — anything an admin adds by hand
  # through AGH's own UI is never touched, regardless of name. AGH's own
  # add endpoint isn't idempotent (a duplicate add just creates a second
  # identical entry, confirmed against its source) — the explicit
  # "does this domain already exist" check below is what keeps re-runs
  # (every boot, every rebuild) safe.
  reconcileScript = pkgs.writeShellApplication {
    name = "dns-cache-reconcile";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.coreutils pkgs.iproute2 ];
    text = ''
      [ -f ${credsFile} ] || exit 0
      # shellcheck disable=SC1090
      set -a
      source ${credsFile}
      set +a
      auth="$DNS_CACHE_ADMIN_USER:$DNS_CACHE_ADMIN_PASSWORD"
      base="http://127.0.0.1:${toString webPort}"

      lan_ip=$(ip -4 -o addr show dev "${lanIf}" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
      if [ -z "$lan_ip" ]; then
        exit 0
      fi

      [ -f ${managedRewritesFile} ] || echo '[]' > ${managedRewritesFile}
      previously_managed=$(cat ${managedRewritesFile})
      wanted='${wantedDomainsJson}'

      current=$(curl -fsS -u "$auth" "$base/control/rewrite/list" 2>/dev/null || echo '[]')

      for d in $(printf '%s' "$wanted" | jq -r '.[]'); do
        exists=$(printf '%s' "$current" | jq --arg d "$d" '[.[] | select(.domain==$d)] | length')
        if [ "$exists" = "0" ]; then
          curl -fsS -u "$auth" -X POST "$base/control/rewrite/add" \
            -H 'Content-Type: application/json' \
            -d "$(jq -n --arg d "$d" --arg a "$lan_ip" '{domain:$d, answer:$a, enabled:true}')" >/dev/null || true
        fi
      done

      for d in $(printf '%s' "$previously_managed" | jq -r '.[]'); do
        if ! printf '%s' "$wanted" | jq -e --arg d "$d" 'index($d)' >/dev/null; then
          answer=$(printf '%s' "$current" | jq -r --arg d "$d" '[.[] | select(.domain==$d)][0].answer // empty')
          if [ -n "$answer" ]; then
            curl -fsS -u "$auth" -X POST "$base/control/rewrite/delete" \
              -H 'Content-Type: application/json' \
              -d "$(jq -n --arg d "$d" --arg a "$answer" '{domain:$d, answer:$a}')" >/dev/null || true
          fi
        fi
      done

      printf '%s' "$wanted" > ${managedRewritesFile}
    '';
  };
in
{
  options.mySystem.features.dnsCache.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      A caching, ad-blocking local DNS resolver (AdGuard Home) — see
      modules/dns-cache.nix. Off by default: a new capability, not
      something every existing box should suddenly start listening on
      port 53 for. Its own web UI is reached through Traefik/Authelia
      like every other admin-ish surface (modules/traefik.nix's
      `adguardhome` backend), not exposed directly on the LAN.
    '';
  };

  config = lib.mkIf cfg.enable {
    services.adguardhome = {
      enable = true;
      host = "127.0.0.1";
      port = webPort;
      # Handled explicitly below instead: DNS (53) needs LAN-wide reach,
      # the web UI (webPort) deliberately doesn't — it's Traefik-only,
      # loopback-bound, same posture as this repo's own dashboard
      # backend (127.0.0.1:8097).
      openFirewall = false;
      mutableSettings = true;
      # Deliberately minimal — only the infrastructure-level keys this
      # box's own firewall rules need to match. Everything an admin
      # would actually want to tune (upstream resolvers, blocklists,
      # filtering rules, the admin account, local DNS rewrites) is left
      # OUT of this attrset on purpose: AdGuard Home's mutableSettings
      # merge overwrites whatever key IS declared here on *every*
      # restart, not just the first (confirmed against the module's own
      # yaml-merge behavior) — declaring `users` or `filtering.rewrites`
      # here would silently wipe a password change or a manually-added
      # rewrite the very next rebuild. The admin account is bootstrapped
      # once via AGH's own install API instead (bootstrapScript above),
      # and this NAS's own service hostnames are reconciled the same way
      # (reconcileScript above) — both leave `settings` alone entirely.
      settings = {
        http.address = "127.0.0.1:${toString webPort}";
        dns = {
          bind_hosts = [ "0.0.0.0" ];
          port = dnsPort;
        };
      };
    };

    systemd.services.dns-cache-bootstrap = {
      description = "One-time AdGuard Home admin account bootstrap";
      after = [ "adguardhome.service" ];
      requires = [ "adguardhome.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe bootstrapScript;
      };
    };

    systemd.services.dns-cache-reconcile = {
      description = "Sync this NAS's own service hostnames into AdGuard Home's local DNS rewrites";
      after = [ "dns-cache-bootstrap.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      requires = [ "dns-cache-bootstrap.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe reconcileScript;
      };
    };

    # Two separate dynamic-attribute assignments to the same
    # interfaces.${lanIf} path within one attrset isn't valid Nix
    # ("dynamic attribute already defined") — has to be one assignment.
    networking.firewall.interfaces.${lanIf} = {
      allowedTCPPorts = [ dnsPort ];
      allowedUDPPorts = [ dnsPort ];
    };
  };
}
