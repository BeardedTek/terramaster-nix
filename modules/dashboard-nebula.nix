{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.dashboardNebula;

  loginEnabled = config.mySystem.features.sso.enable;

  # Not a /persist-backed *overrides* file like dashboard-services.nix,
  # dashboard-network.nix, or dashboard-smtp.nix — modules/nebula.nix's
  # systemd unit just points nebula at this plain runtime file directly
  # (`nebula -config /etc/nebula/config.yaml`), so there's nothing here
  # for a nixos-rebuild to ever need to know about. Bind-mounted from
  # /persist/etc/nebula unconditionally in
  # hosts/terramaster/young/configuration.nix's persistence list, so the
  # parent directory already exists regardless of mySystem.features.nebula.enable.
  configFile = "/etc/nebula/config.yaml";

  runDir = "/run/dashboard-nebula";
  triggerFile = "${runDir}/trigger";
  pendingFile = "${runDir}/pending.yaml";
  resultFile = "${runDir}/result";

  yq = lib.getExe' pkgs.yq-go "yq";

  saveCgi = pkgs.writeShellApplication {
    name = "dashboard-nebula-save-cgi";
    runtimeInputs = [ pkgs.coreutils pkgs.yq-go ];
    text = ''
      body=""
      if [ -n "''${CONTENT_LENGTH:-}" ] && [ "$CONTENT_LENGTH" -gt 0 ]; then
        body=$(head -c "$CONTENT_LENGTH")
      fi

      fail() {
        printf 'Status: 400 Bad Request\r\nContent-Type: application/json\r\n\r\n{"error":"%s"}\n' "$1"
        exit 0
      }

      [ -n "$body" ] || fail "config is empty"

      # Catches "not YAML at all" before this ever reaches disk. yq exits
      # non-zero on a parse error; `-e` alone doesn't matter here since
      # we only care about the parse, not the resulting value.
      if ! printf '%s' "$body" | ${yq} eval '.' - >/dev/null 2>&1; then
        fail "not valid YAML"
      fi

      # Catches "valid YAML but not actually a Nebula config" — every
      # real config needs all three of these non-empty (see this repo's
      # own secrets/extra-files/persist/etc/nebula/config.yaml, which
      # inlines the PEM material directly under pki.ca/cert/key, same
      # shape the Nebula mobile apps produce).
      for key in ca cert key; do
        val=$(printf '%s' "$body" | ${yq} eval ".pki.$key" - 2>/dev/null || true)
        case "$val" in
          ""|null) fail "missing pki.$key — this doesn't look like a complete Nebula config" ;;
        esac
      done

      mkdir -p ${runDir}
      printf '%s' "$body" > ${pendingFile}.tmp
      mv ${pendingFile}.tmp ${pendingFile}
      rm -f ${resultFile}
      touch ${triggerFile}
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n{"ok":true}\n'
    '';
  };

  # Privileged oneshot, triggered by the path unit below — same
  # "unprivileged writer, privileged watcher" shape as
  # modules/traefik-dns01.nix's own applyScript. Never touches
  # modules/system-rebuild.nix's shared runner: this file is read by
  # nebula.service at process start, not baked into the Nix store, so a
  # restart is the whole story.
  applyScript = pkgs.writeShellApplication {
    name = "dashboard-nebula-apply";
    runtimeInputs = [ pkgs.coreutils pkgs.systemd ];
    text = ''
      rm -f ${triggerFile}

      if [ ! -f ${pendingFile} ]; then
        echo "error: no pending config" > ${resultFile}
        exit 0
      fi

      mkdir -p "$(dirname ${configFile})"
      # 640 root:dashboard-nebula, not 600 root:root — this embeds the
      # node's private key, so it still isn't world-readable, but
      # currentCgi (running unprivileged as dashboard-nebula via
      # fcgiwrap) needs to read it back to display it, admin-page-only
      # rationale below. nebula.service itself runs as root (no User=
      # set in modules/nebula.nix), so it can still read it either way.
      install -m 640 -o root -g dashboard-nebula ${pendingFile} ${configFile}
      rm -f ${pendingFile}

      # mySystem.features.nebula.enable being off means the unit simply
      # doesn't exist yet — that's not a failure, the config is just
      # staged for whenever it's turned on (via the Services accordion's
      # own toggle, a separate rebuild-driven flow this module never
      # touches).
      if ! systemctl cat nebula.service >/dev/null 2>&1; then
        echo "ok" > ${resultFile}
      elif systemctl restart nebula.service && systemctl is-active --quiet nebula.service; then
        echo "ok" > ${resultFile}
      else
        echo "error: nebula failed to restart — check journalctl -u nebula" > ${resultFile}
      fi
    '';
  };

  # Same "still fresh" window idiom as traefik-dns01-status-cgi — this
  # operation finishes in well under a second.
  statusCgi = pkgs.writeShellApplication {
    name = "dashboard-nebula-status-cgi";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: text/plain\r\n\r\n'
      if [ -f ${resultFile} ] && [ -n "$(find ${resultFile} -mmin -2 2>/dev/null)" ]; then
        cat ${resultFile}
      elif [ -f ${triggerFile} ] || [ -f ${pendingFile} ]; then
        echo "pending"
      else
        echo "idle"
      fi
    '';
  };

  # Echoes the saved config back (unlike modules/dashboard-smtp.nix's
  # password, which never round-trips) — this whole page sits behind
  # the same admin-only gate as every other preferences endpoint, so an
  # admin reviewing/editing their own node's config here is the same
  # trust boundary as them reading it off disk directly. --rawfile
  # loads the file as a plain string (no attempt to parse it), so
  # arbitrary YAML content (quotes, backslashes, embedded PEM) round-
  # trips through JSON safely regardless of what it contains.
  currentCgi = pkgs.writeShellApplication {
    name = "dashboard-nebula-current-cgi";
    runtimeInputs = [ pkgs.coreutils pkgs.jq ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      if [ -s ${configFile} ]; then
        jq -n --rawfile config ${configFile} '{configSet:true, config:$config}'
      else
        echo '{"configSet":false,"config":""}'
      fi
    '';
  };
in
{
  options.mySystem.features.dashboardNebula.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Dashboard-driven Nebula config upload — see
      modules/dashboard-nebula.nix and the "Mesh VPN Networks" group
      inside the Services accordion on the System Preferences page.
      Independent of modules/system-rebuild.nix's shared rebuild runner:
      /etc/nebula/config.yaml is a plain runtime file nebula.service
      reads at start, so saving here only restarts that one service, it
      never rebuilds the system. The nebula.enable flag itself (whether
      the service exists at all) is a separate, ordinary flag inside
      modules/dashboard-services.nix's own rebuild-driven flow.
    '';
  };

  config = lib.mkIf cfg.enable {
    users.users.dashboard-nebula = { isSystemUser = true; group = "dashboard-nebula"; };
    users.groups.dashboard-nebula = { };

    systemd.tmpfiles.rules = [
      "d ${runDir} 0750 dashboard-nebula dashboard-nebula - -"
      # Fixes ownership/permissions on every boot — a config saved
      # before this file's own currentCgi started reading it back
      # (600 root:root) would otherwise never get upgraded to 640
      # root:dashboard-nebula on its own, same class of bug
      # modules/traefik-dns01.nix's own tmpfiles fix addresses for
      # exactly the same reason. `z` is a no-op if the file isn't there
      # yet.
      "z ${configFile} 0640 root dashboard-nebula - -"
    ];

    # Never wantedBy anything — purely triggered by the path unit below.
    systemd.services.dashboard-nebula-apply = {
      description = "Write an uploaded Nebula config and restart nebula.service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe applyScript;
      };
    };
    systemd.paths.dashboard-nebula-apply = {
      description = "Watch for a web-uploaded Nebula config";
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathExists = triggerFile;
    };

    services.fcgiwrap.instances.dashboard-nebula = {
      process = {
        user = "dashboard-nebula";
        group = "dashboard-nebula";
      };
      socket = {
        user = config.services.nginx.user;
        group = config.services.nginx.group;
      };
    };

    # Rides on the existing dashboard vhost, same shape as
    # modules/traefik-dns01.nix. Admin-only throughout — this handles a
    # private key.
    services.nginx.virtualHosts.dashboard.locations = {
      "= /preferences/nebula/current" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-nebula.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe currentCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/nebula/save" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-nebula.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe saveCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param CONTENT_TYPE $content_type;
          fastcgi_param CONTENT_LENGTH $content_length;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/nebula/status" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-nebula.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe statusCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
    };
  };
}
