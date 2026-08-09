{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.dashboardTailscale;

  loginEnabled = config.mySystem.features.sso.enable;

  # Same literal path modules/tailscale.nix's authKeyFile already points
  # at — a plain runtime file nixpkgs' own tailscaled-autoconnect.service
  # reads whenever BackendState isn't already Running, not baked into
  # the Nix store, so saving here only restarts that one service, never
  # a rebuild. Bind-mounted from /persist/etc/tailscale unconditionally
  # in hosts/terramaster/young/configuration.nix's persistence list, so
  # the parent directory already exists regardless of
  # mySystem.features.tailscale.enable.
  authKeyFile = "/etc/tailscale/authkey";

  runDir = "/run/dashboard-tailscale";
  triggerFile = "${runDir}/trigger";
  pendingFile = "${runDir}/pending.txt";
  resultFile = "${runDir}/result";

  # The interactive-login half — a genuinely different mechanism from
  # the auth-key flow above, not a variation of it: `tailscale up` with
  # no key blocks for as long as it takes the admin to click the
  # printed link and finish the browser flow (could be minutes), so
  # nothing here can synchronously wait on it the way saveCgi/applyScript
  # do. loginCgi is fire-and-forget; the frontend polls loginStatusCgi
  # for the URL to appear, then separately polls the already-built
  # currentCgi for BackendState to flip to Running.
  loginTriggerFile = "${runDir}/login-trigger";
  loginLogFile = "${runDir}/login.log";

  saveCgi = pkgs.writeShellApplication {
    name = "dashboard-tailscale-save-cgi";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      body=""
      if [ -n "''${CONTENT_LENGTH:-}" ] && [ "$CONTENT_LENGTH" -gt 0 ]; then
        body=$(head -c "$CONTENT_LENGTH")
      fi

      fail() {
        printf 'Status: 400 Bad Request\r\nContent-Type: application/json\r\n\r\n{"error":"%s"}\n' "$1"
        exit 0
      }

      [ -n "$body" ] || fail "auth key is empty"
      # The only real constraint — this ends up as the sole content of
      # a file `cat`-ed into a single CLI argument by nixpkgs' own
      # tailscaled-autoconnect.service, so a newline would corrupt that.
      case "$body" in
        *$'\n'*) fail "invalid auth key" ;;
      esac

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
  # modules/dashboard-nebula.nix's own applyScript. Unlike that one,
  # the restart this triggers (tailscaled-autoconnect.service) is
  # Type=notify and *exits* once BackendState reaches Running (see
  # nixpkgs' own tailscale.nix) rather than staying continuously
  # active — so success is read from `systemctl restart`'s own exit
  # code (the job only completes once the ready notification arrives,
  # or fails/times out per modules/tailscale.nix's own
  # TimeoutStartSec), not from a follow-up `is-active` check the way
  # nebula.service's own restart is checked.
  applyScript = pkgs.writeShellApplication {
    name = "dashboard-tailscale-apply";
    runtimeInputs = [ pkgs.coreutils pkgs.systemd ];
    text = ''
      rm -f ${triggerFile}

      if [ ! -f ${pendingFile} ]; then
        echo "error: no pending auth key" > ${resultFile}
        exit 0
      fi

      mkdir -p "$(dirname ${authKeyFile})"
      # 600 root:root — never read back by the unprivileged CGI; status
      # comes from the operator-granted `tailscale status` command
      # instead (see modules/tailscale.nix's extraSetFlags), not this
      # file.
      install -m 600 -o root -g root ${pendingFile} ${authKeyFile}
      rm -f ${pendingFile}

      # mySystem.features.tailscale.enable being off means the unit
      # simply doesn't exist yet — not a failure, the key is just
      # staged for whenever it's turned on (via the Services
      # accordion's own toggle, a separate rebuild-driven flow this
      # module never touches). Same posture as
      # dashboard-nebula-apply's own restart guard.
      if ! systemctl cat tailscaled-autoconnect.service >/dev/null 2>&1; then
        echo "ok" > ${resultFile}
      elif systemctl restart tailscaled-autoconnect.service; then
        echo "ok" > ${resultFile}
      else
        echo "error: authentication failed — check the auth key and try again (see journalctl -u tailscaled-autoconnect)" > ${resultFile}
      fi
    '';
  };

  # Fire-and-forget — unlike saveCgi, nothing here waits on a result via
  # statusCgi; the frontend polls loginStatusCgi for the URL instead.
  # Clears any previous run's log first so a stale link from an earlier
  # attempt can never be shown for a fresh click.
  loginCgi = pkgs.writeShellApplication {
    name = "dashboard-tailscale-login-cgi";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      mkdir -p ${runDir}
      rm -f ${loginLogFile}
      touch ${loginTriggerFile}
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n{"ok":true}\n'
    '';
  };

  # Privileged oneshot, triggered by its own path unit below — deliberately
  # a *separate* trigger/unit pair from dashboard-tailscale-apply, since
  # this one can legitimately run for minutes (however long the admin
  # takes to click the link and finish the browser flow) while that one
  # is bounded to ~60s. `|| true` on the tailscale invocation itself is
  # intentional: a non-zero exit here just means the browser flow wasn't
  # completed or the daemon's own default timeout hit, not a bug in this
  # script — the frontend finds out either way by polling currentCgi for
  # BackendState, not this unit's own exit status.
  loginApplyScript = pkgs.writeShellApplication {
    name = "dashboard-tailscale-login-apply";
    runtimeInputs = [ pkgs.coreutils pkgs.systemd pkgs.tailscale ];
    text = ''
      rm -f ${loginTriggerFile}

      : > ${loginLogFile}.tmp
      mv ${loginLogFile}.tmp ${loginLogFile}
      chown dashboard-tailscale:dashboard-tailscale ${loginLogFile}
      chmod 640 ${loginLogFile}

      if ! systemctl cat tailscaled.service >/dev/null 2>&1; then
        echo "Tailscale isn't enabled yet — turn it on from System Preferences first." >> ${loginLogFile}
        exit 0
      fi

      # Once a box has ever connected, tailscaled carries a non-default
      # --operator setting (see modules/tailscale.nix's extraSetFlags —
      # same literal, duplicated here for the same reason authKeyFile is
      # above). A bare `tailscale up` on a box in that state refuses to
      # run at all ("requires mentioning all non-default flags") rather
      # than printing a login URL, so it must be repeated on every call,
      # not just the one that originally set it.
      tailscale up --operator=dashboard-tailscale >> ${loginLogFile} 2>&1 || true
    '';
  };

  # Matches just the URL itself, not the surrounding "To authenticate,
  # visit:" text — robust to that wording shifting between Tailscale
  # versions, since only the URL shape is actually load-bearing here.
  loginStatusCgi = pkgs.writeShellApplication {
    name = "dashboard-tailscale-login-status-cgi";
    runtimeInputs = [ pkgs.coreutils pkgs.gnugrep pkgs.jq ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      url=""
      if [ -f ${loginLogFile} ]; then
        url=$(grep -oE 'https://login\.tailscale\.com/a/[A-Za-z0-9]+' ${loginLogFile} | head -n1 || true)
      fi
      if [ -n "$url" ]; then
        jq -n --arg u "$url" '{loginUrl: $u}'
      else
        echo '{"loginUrl": null}'
      fi
    '';
  };

  # Same "still fresh" window idiom as dashboard-nebula-status-cgi —
  # this operation is bounded by modules/tailscale.nix's own
  # TimeoutStartSec (60s), not instant, but still well under 2 minutes.
  statusCgi = pkgs.writeShellApplication {
    name = "dashboard-tailscale-status-cgi";
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

  # Runs as the unprivileged dashboard-tailscale user — works without
  # root or sudo purely because of modules/tailscale.nix's
  # `--operator=dashboard-tailscale` grant (tailscaled's own built-in
  # mechanism for letting one specific Unix user talk to its control
  # socket directly). Degrades to a plain "not enabled" response rather
  # than erroring if the tailscale binary can't reach a running daemon
  # at all (feature currently off, or genuinely never authenticated) —
  # `tailscale status --json` itself still succeeds and reports
  # BackendState:"NeedsLogin" for the ordinary not-yet-authenticated
  # case, so this fallback is only for ", is the daemon even there."
  currentCgi = pkgs.writeShellApplication {
    name = "dashboard-tailscale-current-cgi";
    runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.tailscale ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      raw=$(tailscale status --json 2>/dev/null) || raw=""
      if [ -z "$raw" ] || ! printf '%s' "$raw" | jq -e . >/dev/null 2>&1; then
        echo '{"backendState":"NotEnabled"}'
      else
        printf '%s' "$raw" | jq '{
          backendState: (.BackendState // "Unknown"),
          tailscaleIp: (.Self.TailscaleIPs[0] // null),
          dnsName: (.Self.DNSName // null)
        }'
      fi
    '';
  };

  # Seeds a harmless empty authkey file before
  # tailscaled-autoconnect.service's very first start — without this, a
  # fresh box that enables Tailscale but has never had a key pasted
  # through the dashboard yet would hit nixpkgs' own autoconnect script
  # trying to `cat` a file that doesn't exist at all. Never touches an
  # existing file — once an admin has actually saved a real key, this
  # is a permanent no-op. Same shape as
  # modules/traefik-dns01.nix's own defaultsScript.
  defaultsScript = pkgs.writeShellApplication {
    name = "dashboard-tailscale-defaults";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      if [ ! -f ${authKeyFile} ]; then
        mkdir -p "$(dirname ${authKeyFile})"
        : > ${authKeyFile}.tmp
        mv ${authKeyFile}.tmp ${authKeyFile}
        chmod 600 ${authKeyFile}
      fi
    '';
  };
in
{
  options.mySystem.features.dashboardTailscale.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Dashboard-driven Tailscale authentication — see
      modules/dashboard-tailscale.nix and the "Mesh VPN Networks"
      category on the Service Configuration page. Independent of
      modules/system-rebuild.nix's shared rebuild runner:
      /etc/tailscale/authkey is a plain runtime file nixpkgs' own
      tailscaled-autoconnect.service reads, so saving here only
      restarts that one service, it never rebuilds the system. The
      tailscale.enable flag itself (whether the service exists at all)
      is a separate, ordinary flag inside
      modules/dashboard-services.nix's own rebuild-driven flow.
    '';
  };

  config = lib.mkIf cfg.enable {
    users.users.dashboard-tailscale = { isSystemUser = true; group = "dashboard-tailscale"; };
    users.groups.dashboard-tailscale = { };

    systemd.tmpfiles.rules = [
      "d ${runDir} 0750 dashboard-tailscale dashboard-tailscale - -"
    ];

    systemd.services.dashboard-tailscale-defaults = {
      description = "Seed an empty /etc/tailscale/authkey if none exists yet";
      before = [ "tailscaled-autoconnect.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe defaultsScript;
      };
    };

    # Never wantedBy anything — purely triggered by the path unit below.
    systemd.services.dashboard-tailscale-apply = {
      description = "Write a pasted Tailscale auth key and (re)authenticate";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe applyScript;
      };
    };
    systemd.paths.dashboard-tailscale-apply = {
      description = "Watch for a web-submitted Tailscale auth key";
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathExists = triggerFile;
    };

    # Never wantedBy anything — purely triggered by the path unit below.
    # A much longer TimeoutStartSec than dashboard-tailscale-apply's
    # (60s): nothing waits on this unit synchronously (the frontend
    # polls loginStatusCgi/currentCgi instead), so there's no cost to
    # giving the admin several real minutes to click the link and
    # finish the browser flow before this gets killed.
    systemd.services.dashboard-tailscale-login-apply = {
      description = "Run `tailscale up` interactively and log the resulting login URL";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe loginApplyScript;
        TimeoutStartSec = 300;
      };
    };
    systemd.paths.dashboard-tailscale-login-apply = {
      description = "Watch for a web-triggered interactive Tailscale login";
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathExists = loginTriggerFile;
    };

    services.fcgiwrap.instances.dashboard-tailscale = {
      process = {
        user = "dashboard-tailscale";
        group = "dashboard-tailscale";
      };
      socket = {
        user = config.services.nginx.user;
        group = config.services.nginx.group;
      };
    };

    # Rides on the existing dashboard vhost, same shape as
    # modules/dashboard-nebula.nix. Admin-only throughout — this
    # handles an auth key that can add/remove this box from the tailnet.
    services.nginx.virtualHosts.dashboard.locations = {
      "= /preferences/tailscale/current" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-tailscale.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe currentCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/tailscale/save" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-tailscale.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe saveCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param CONTENT_TYPE $content_type;
          fastcgi_param CONTENT_LENGTH $content_length;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/tailscale/status" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-tailscale.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe statusCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/tailscale/login" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-tailscale.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe loginCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/tailscale/login-status" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-tailscale.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe loginStatusCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
    };
  };
}
