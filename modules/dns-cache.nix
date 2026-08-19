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
  # Applied via services.adguardhome.extraArgs' --web-addr below, from
  # AGH's very first start — not via services.adguardhome.settings, see
  # that option's own (absence of a) comment for why.
  webPort = 3080;
  dnsPort = 53;

  # Fixed, not generated — AdGuard Home's own login is a second,
  # redundant lock on top of Authelia here, not the real access control:
  # its web UI is loopback-bound (services.adguardhome's extraArgs
  # below) and only ever reachable at all through Traefik's Authelia
  # ForwardAuth gate (modules/authelia.nix's candidateProtectedServices
  # entry, admins-only). Anyone who can reach webPort on loopback
  # directly already has shell/service access to this box, at which
  # point AdGuard Home's own login isn't the thing protecting anything.
  # This also sidesteps a real gap in AGH itself: it has no API to
  # change an existing user's password after first-run setup (confirmed
  # against its own source) — a generated, unrecoverable-without-SSH
  # password would have been actively worse for a "non-expert admin"
  # feature than a fixed, known one.
  adminUser = "admin";
  # Not plain "admin": AdGuard Home's own install/configure endpoint
  # enforces a hard minimum of 8 runes (PasswordMinRunes) and rejects
  # anything shorter with a 422 — confirmed the hard way on a real box.
  # "adminadmin" is the shortest value that keeps the same fixed/known
  # intent as the original admin/admin choice while actually clearing
  # that floor.
  adminPassword = "adminadmin";
  # Ephemeral, not persisted — this box's own tmpfs /run, matching every
  # other feature's own runtime-state convention (e.g.
  # /run/dashboard-svcconfig, /run/system-rebuild). Losing this on
  # reboot is harmless either way: bootstrapMarker not surviving just
  # means one extra (cheap, idempotent — see the 403 branch below)
  # recheck on next boot; managedRewritesFile not surviving just means
  # this NAS's own rewrites get safely re-verified/re-added (never
  # duplicated — see reconcileScript's own "does this already exist"
  # check) rather than only reconciling removals from *before* that
  # reboot.
  runDir = "/run/dns-cache";
  bootstrapMarker = "${runDir}/bootstrapped";
  managedRewritesFile = "${runDir}/managed-rewrites.json";

  # Two rewrites instead of one exact entry per enabled service (the
  # original design): the wildcard ("*.<host>.<domain>") covers every
  # current *and future* service under this host without needing a
  # rebuild each time a new one is enabled — AdGuard Home's own rewrite
  # matcher supports "*.suffix" natively (internal/filtering/rewrites.go)
  # — but a wildcard alone never matches the bare host.domain itself
  # (matchDomainWildcard requires something *before* the suffix), so
  # that's added as its own explicit entry alongside it. Exact matches
  # always take precedence over the wildcard, so neither can collide
  # with anything more specific an admin later adds by hand. Unlike the
  # old per-service list generated from mySystem.serviceBackends, both
  # of these survive a full AdGuard Home state wipe with nothing to
  # regenerate from Nix at all.
  wantedDomains = [ "${hostName}.${domain}" "*.${hostName}.${domain}" ];
  wantedDomainsJson = builtins.toJSON wantedDomains;

  # Completes AdGuard Home's own first-run setup wizard via its install
  # API instead of a human clicking through it — same "no manual
  # first-boot step" posture as filebrowser-setup.service's own admin
  # bootstrap. Guarded on bootstrapMarker so this only ever runs once
  # per box (once it's actually succeeded, or found setup already done
  # elsewhere — see the 403 branch below).
  #
  # Talks to webPort directly (not AGH's own built-in first-run default,
  # 3000) — services.adguardhome.extraArgs below passes AGH's
  # `--web-addr` flag, which only overrides its *in-memory* bind
  # address for this run (confirmed against AGH's own source:
  # setupBindOpts mutates config.HTTPConfig.Address only, no disk I/O)
  # and is applied independently of AGH's first-run detection. That
  # detection is a dumb "does a config file already exist on disk"
  # check (internal/home/home.go's detectFirstRun — a bare os.Stat, it
  # never looks at *content*, e.g. whether any users are configured) —
  # so services.adguardhome.settings is deliberately never declared
  # anywhere in this module: writing ANY settings file before AGH's
  # first boot, even one that says nothing about users, makes AGH think
  # setup already happened, permanently 404s every /control/install/*
  # route, with no supported way to un-stick it short of wiping its
  # state directory. Confirmed the hard way: an earlier version of this
  # module declared `settings.http.address`/`settings.dns` up front,
  # and that alone was enough to lock a real box out of ever
  # bootstrapping an admin account. AGH's own install/configure call
  # (below) is the *only* thing that ever sets DNS's bind address (the
  # web address is already correct from --web-addr) — exactly what a
  # human clicking through the real wizard would do.
  bootstrapScript = pkgs.writeShellApplication {
    name = "dns-cache-bootstrap";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.coreutils ];
    text = ''
      if [ -f ${bootstrapMarker} ]; then
        exit 0
      fi
      mkdir -p ${runDir}

      # Wait for AdGuard Home's install-wizard HTTP server to actually
      # be listening — only matters on a genuinely fresh
      # /var/lib/private/AdGuardHome.
      waited=0
      until curl -fsS -o /dev/null "http://127.0.0.1:${toString webPort}/control/install/get_addresses" 2>/dev/null; do
        waited=$((waited + 1))
        [ "$waited" -ge 60 ] && break
        sleep 1
      done

      # No -f here on purpose: -f makes curl treat a 4xx response as a
      # curl *failure* (nonzero exit), which both discards the exit code
      # we need to distinguish 403-from-everything-else AND (since -w
      # still writes its output before curl exits nonzero) triggers the
      # `|| echo 000` fallback right after it, concatenating into a
      # bogus "403000" that matches neither branch below. Confirmed the
      # hard way on a real box. -sS alone is enough: it just suppresses
      # curl's own progress meter/errors and gives us the true code.
      status=$(curl -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${toString webPort}/control/install/get_addresses" 2>/dev/null || echo 000)
      # 403 means setup already completed out-of-band (e.g. a human
      # clicked through AGH's own wizard manually before this ran) —
      # nothing to do except record that and stop, never overwriting
      # whatever credentials already exist. Anything else that isn't a
      # clean 200 (still starting up, wrong version, genuinely
      # unreachable) is left un-marked so this retries on the next
      # boot, rather than silently giving up forever.
      if [ "$status" = "403" ]; then
        touch ${bootstrapMarker}
        exit 0
      fi
      if [ "$status" != "200" ]; then
        echo "AdGuard Home's install API returned '$status', not 200/403 — can't bootstrap yet (will retry next boot)." >&2
        exit 1
      fi

      body=$(jq -n --arg u ${adminUser} --arg p ${adminPassword} \
        --argjson webport ${toString webPort} --argjson dnsport ${toString dnsPort} \
        '{web:{ip:"127.0.0.1",port:$webport}, dns:{ip:"0.0.0.0",port:$dnsport}, username:$u, password:$p, language:"en"}')
      curl -fsS -X POST "http://127.0.0.1:${toString webPort}/control/install/configure" \
        -H 'Content-Type: application/json' -d "$body" >/dev/null

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
    # gawk, not just coreutils/iproute2 — awk isn't part of coreutils
    # (confirmed the hard way: exit 127 "command not found" on a real
    # box — writeShellApplication's shellcheck only checks shell syntax,
    # it has no idea whether a given command is actually reachable on
    # $PATH at runtime, so this class of bug survives a clean build).
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.coreutils pkgs.iproute2 pkgs.gawk ];
    text = ''
      auth="${adminUser}:${adminPassword}"
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
    # Deliberately no `settings`/`mutableSettings`/`host`/`port` here —
    # see bootstrapScript's own comment above for why: writing *any*
    # services.adguardhome.settings before AGH's first boot makes it
    # think setup is already done and permanently disables the install
    # API this module depends on (this module's own `host`/`port`
    # options are inert unless `settings` is also set anyway — confirmed
    # against the nixpkgs module's own source — so setting only those
    # wouldn't have helped). `extraArgs`' `--web-addr` is different: it
    # only overrides AGH's *in-memory* bind address for this run, with
    # no disk write and no effect on first-run detection (confirmed
    # against AGH's own source) — so the web UI binds straight to its
    # real, permanent, Traefik-only loopback address from the very
    # first instant AGH starts, without ever needing AGH's own built-in
    # first-run default port (3000) at all, and DNS's own bind address
    # is set the same way `host`/`port` normally would be: by
    # bootstrapScript's install/configure call below, exactly what a
    # human clicking through the real wizard would do.
    services.adguardhome = {
      enable = true;
      openFirewall = false;
      extraArgs = [ "--web-addr" "127.0.0.1:${toString webPort}" ];
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
