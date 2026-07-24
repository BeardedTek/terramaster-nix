{ config, lib, pkgs, ... }:

let
  lanIf = config.mySystem.lanInterface;
  backends = config.mySystem.serviceBackends; # set by modules/traefik.nix

  # Generated from mySystem.contactInfo (set per-host, e.g.
  # hosts/young/configuration.nix) rather than hardcoded into the Hugo
  # content itself — Hugo auto-loads any data/*.json file as
  # .Site.Data.contact, read by dashboard/layouts/partials/contact-info.html
  # (shared by the footer and the Help page's {{< contact >}} shortcode).
  contactDataFile = pkgs.writeText "contact.json" (builtins.toJSON config.mySystem.contactInfo);

  # Built once at nixos-rebuild time from ../dashboard — the Hugo source
  # for this. No npm/webpack/Tailwind build here on purpose: the theme's
  # CSS/JS bundles are vendored pre-built into dashboard/static (see
  # docs/ARCHITECTURE.md) specifically to keep this a single lightweight
  # `hugo` invocation, nothing heavier.
  dashboardSite = pkgs.stdenv.mkDerivation {
    pname = "young-dashboard";
    version = "1";
    src = ../dashboard;
    nativeBuildInputs = [ pkgs.hugo ];
    dontBuild = true;
    installPhase = ''
      mkdir -p data
      cp ${contactDataFile} data/contact.json
      hugo --minify -d $out
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
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.iproute2 pkgs.gawk pkgs.iputils pkgs.netcat ];
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

      # $3, if given, is a host to ping to determine "up" instead of trusting
      # operstate. Needed for nebula1 specifically: TUN/overlay interfaces
      # like Nebula's have no physical carrier to detect, so the kernel
      # reports operstate "unknown" even when the tunnel is working fine —
      # confirmed the hard way, the dashboard showed Nebula as permanently
      # "down" despite it working. Physical ethernet (lan) doesn't have this
      # problem, so it keeps using the cheaper operstate check.
      # Tradeoff: this makes Nebula's status depend on one specific peer
      # (the lighthouse) being reachable, not just the tunnel itself.
      net_json() {
        local iface="$1" label="$2" ping_target="''${3:-}" up="false" ip=""
        if [ -e "/sys/class/net/$iface" ]; then
          ip=$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
          if [ -n "$ping_target" ]; then
            ping -c1 -W1 "$ping_target" >/dev/null 2>&1 && up="true"
          else
            state=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null || echo down)
            [ "$state" = "up" ] && up="true"
          fi
        fi
        jq -n --arg iface "$label" --argjson up "$up" --arg ip "''${ip:-}" \
          '{iface:$iface, up:$up, ip:$ip}'
      }
      network=$(jq -s '.' \
        <(net_json nebula1 nebula 10.100.0.1) \
        <(net_json "${lanIf}" lan))

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
        jq -n --arg name "$name" --argjson up "$up" '{name:$name, up:$up}'
      }
      services=$(jq -s '.' \
        ${lib.concatStringsSep " \\\n        " (
          lib.mapAttrsToList (name: port: "<(service_json ${name} ${toString port})") backends
        )})

      jq -n --arg generated_at "$(date -Is)" \
            --argjson disks "$disks" \
            --argjson load "$load" \
            --argjson memory "$memory" \
            --argjson network "$network" \
            --argjson services "$services" \
            '{generated_at:$generated_at, disks:$disks, load:$load, memory:$memory, network:$network, services:$services}' \
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
      locations."= /metrics.json".alias = "/var/lib/dashboard/metrics.json";
    };
  };

  networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 8097 ];
  networking.firewall.interfaces.${lanIf}.allowedTCPPorts = [ 8097 ];
}
