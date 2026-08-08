{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.dashboardSmtp;
  smtp = config.mySystem.smtp;

  loginEnabled = config.mySystem.features.sso.enable;

  # Same /persist-backed overrides shape as dashboard-services.nix and
  # dashboard-network.nix — a real file on disk, independent of which
  # checkout is doing the building, conditionally imported by flake.nix.
  # Forces the whole mySystem.smtp submodule at once (a single nullable
  # option, unlike dashboard-services.nix's many independent boolean
  # leaves) rather than per-field mkForce.
  overridesFile = "/persist/nixos-smtp-overrides.nix";

  # The real credential never goes through the overrides file (which
  # ends up as plain-text Nix source under /persist, readable by
  # anything that can read that path) — modules/smtp-relay.nix already
  # keeps it in exactly this file, out-of-repo, delivered via
  # secrets/extra-files/persist/etc/opensmtpd/secrets.example. Writing
  # here directly is the same file that module's `table secrets
  # file:/etc/opensmtpd/secrets` reads (bind-mounted 1:1 by
  # impermanence, see hosts/terramaster/young/configuration.nix's
  # persistence list).
  secretsFile = "/persist/etc/opensmtpd/secrets";

  runDir = "/run/dashboard-smtp";
  triggerFile = "${runDir}/trigger";
  pendingFile = "${runDir}/pending.json";

  # The actual nixos-rebuild is shared with self-update.nix and
  # dashboard-services.nix via modules/system-rebuild.nix — see that
  # file's own comment for why. host/port/scheme/sender/username are
  # baked into modules/smtp-relay.nix's serverConfiguration at build
  # time, so any change to them genuinely needs a rebuild, not just a
  # service restart.
  sharedRunDir = "/run/system-rebuild";
  sharedRequestFile = "${sharedRunDir}/request.json";
  sharedTriggerFile = "${sharedRunDir}/trigger";
  sharedProgressFile = "${sharedRunDir}/progress.json";
  sharedBuildLogFile = "${sharedRunDir}/build.log";
  sharedApplyingFile = "${sharedRunDir}/applying";

  # Build-time snapshot of what's actually running right now, regardless
  # of whether it came from variables.nix or a previously-saved
  # overrides file — same shape dashboard-services.nix's own
  # currentState/stateJson already establishes. World-readable via
  # environment.etc, so currentCgi is a plain `cat` plus the one bit
  # (passwordSet) that genuinely needs a live filesystem check.
  currentState =
    if smtp != null then {
      enable = true;
      host = smtp.host;
      port = smtp.port;
      scheme = smtp.scheme;
      sender = smtp.sender;
      username = smtp.username;
    } else {
      enable = false;
      host = "";
      port = 587;
      scheme = "submission";
      sender = "";
      username = "";
    };
  stateJson = pkgs.writeText "dashboard-smtp-state.json" (builtins.toJSON currentState);

  # Shared by saveCgi (only allow a blank password field to mean "keep
  # what's there" when something real is already set) and currentCgi
  # (report that same fact to the frontend, as a boolean, never the
  # actual value). secrets.example ships literal CHANGE-ME placeholders
  # — a box that's never had this page touched, or that only ever ran
  # the example file through deployment as-is, has no real password yet.
  passwordSetCheckFn = ''
    password_already_set() {
      if [ -f ${secretsFile} ] && ! grep -q "CHANGE-ME" ${secretsFile}; then
        echo true
      else
        echo false
      fi
    }
  '';

  saveCgi = pkgs.writeShellApplication {
    name = "dashboard-smtp-save-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.gnugrep ];
    text = ''
      ${passwordSetCheckFn}

      body=""
      if [ -n "''${CONTENT_LENGTH:-}" ] && [ "$CONTENT_LENGTH" -gt 0 ]; then
        body=$(head -c "$CONTENT_LENGTH")
      fi

      fail() {
        printf 'Status: 400 Bad Request\r\nContent-Type: application/json\r\n\r\n{"error":"%s"}\n' "$1"
        exit 0
      }

      enable_val=$(printf '%s' "$body" | jq -r '.enable' 2>/dev/null || true)
      case "$enable_val" in
        true|false) ;;
        *) fail "missing or invalid enable" ;;
      esac

      request_json=$(jq -n --argjson v "$enable_val" '{enable: $v}')

      if [ "$enable_val" = "true" ]; then
        host_val=$(printf '%s' "$body" | jq -r '.host // empty' 2>/dev/null || true)
        case "$host_val" in
          "") fail "host is required" ;;
        esac
        case "$host_val" in
          *[!a-zA-Z0-9.-]*) fail "invalid host" ;;
        esac

        port_val=$(printf '%s' "$body" | jq -r '.port // empty' 2>/dev/null || true)
        case "$port_val" in
          ""|*[!0-9]*) fail "invalid port" ;;
        esac
        if [ "$port_val" -lt 1 ] || [ "$port_val" -gt 65535 ]; then
          fail "invalid port"
        fi

        scheme_val=$(printf '%s' "$body" | jq -r '.scheme // empty' 2>/dev/null || true)
        case "$scheme_val" in
          smtp|submission|submissions) ;;
          *) fail "invalid scheme" ;;
        esac

        # Both fields are interpolated straight into a Nix source file
        # below (applyScript) — the allowed set deliberately excludes
        # quotes/backslashes/whitespace so neither can break out of the
        # Nix string it's written into. username additionally ends up in
        # the OpenSMTPD secrets table (a plain `label value` line) where
        # the same set keeps it safely colon- and whitespace-free.
        sender_val=$(printf '%s' "$body" | jq -r '.sender // empty' 2>/dev/null || true)
        case "$sender_val" in
          "") fail "sender address is required" ;;
        esac
        case "$sender_val" in
          *[!a-zA-Z0-9.@_+-]*) fail "invalid sender address" ;;
        esac
        case "$sender_val" in
          *@*) ;;
          *) fail "invalid sender address" ;;
        esac

        username_val=$(printf '%s' "$body" | jq -r '.username // empty' 2>/dev/null || true)
        case "$username_val" in
          "") fail "username is required" ;;
        esac
        case "$username_val" in
          *[!a-zA-Z0-9.@_+-]*) fail "invalid username" ;;
        esac

        password_val=$(printf '%s' "$body" | jq -r '.password // empty' 2>/dev/null || true)
        case "$password_val" in
          *$'\n'*) fail "invalid password" ;;
        esac
        password_set=$(password_already_set)
        if [ -z "$password_val" ] && [ "$password_set" = "false" ]; then
          fail "password is required"
        fi

        request_json=$(printf '%s' "$request_json" | jq \
          --arg host "$host_val" --argjson port "$port_val" --arg scheme "$scheme_val" \
          --arg sender "$sender_val" --arg username "$username_val" --arg password "$password_val" \
          '. + {host: $host, port: $port, scheme: $scheme, sender: $sender, username: $username, password: $password}')
      fi

      mkdir -p ${runDir}
      printf '%s' "$request_json" > ${pendingFile}.tmp
      mv ${pendingFile}.tmp ${pendingFile}
      touch ${triggerFile}
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n{"ok":true}\n'
    '';
  };

  # Privileged oneshot, triggered by the path unit below — same
  # "unprivileged writer (saveCgi), privileged watcher" shape
  # dashboard-services.nix's own applyScript already establishes. Short-
  # lived: never itself runs nixos-rebuild (handed off to the shared
  # runner), so it isn't exposed to that runner's self-kill problem and
  # doesn't need restartIfChanged/X-StopOnRemoval.
  applyScript = pkgs.writeShellApplication {
    name = "dashboard-smtp-apply";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.systemd ];
    text = ''
      rm -f ${triggerFile}

      if [ ! -f ${pendingFile} ]; then
        exit 0
      fi

      # Both this and self-update.nix/dashboard-services.nix ultimately
      # hand off to the same shared rebuild runner, which can't safely
      # run twice at once — leave pendingFile in place if it's already
      # busy; the next successful save naturally picks it back up.
      if [ -f ${sharedApplyingFile} ]; then
        exit 0
      fi

      enable_val=$(jq -r '.enable' ${pendingFile})

      if [ "$enable_val" = "true" ]; then
        host_val=$(jq -r '.host' ${pendingFile})
        port_val=$(jq -r '.port' ${pendingFile})
        scheme_val=$(jq -r '.scheme' ${pendingFile})
        sender_val=$(jq -r '.sender' ${pendingFile})
        username_val=$(jq -r '.username' ${pendingFile})
        password_val=$(jq -r '.password' ${pendingFile})

        {
          echo "{ lib, ... }:"
          echo "{"
          echo "  config.mySystem.smtp = lib.mkForce {"
          echo "    host = \"$host_val\";"
          echo "    port = $port_val;"
          echo "    scheme = \"$scheme_val\";"
          echo "    sender = \"$sender_val\";"
          echo "    username = \"$username_val\";"
          echo "  };"
          echo "}"
        } > ${overridesFile}.tmp
        mv ${overridesFile}.tmp ${overridesFile}

        # Blank password field means "keep the existing one" — saveCgi
        # already enforced that a blank is only ever allowed when a real
        # one is already on disk, so an empty password_val here is
        # never a first-time save. The upcoming rebuild switches
        # modules/smtp-relay.nix's config (host/port/scheme change or
        # not), but won't itself restart opensmtpd just because this
        # out-of-Nix-store file changed — try-restart here makes a new
        # password take effect immediately rather than waiting on
        # whatever else happens to bounce that unit next.
        if [ -n "$password_val" ]; then
          mkdir -p "$(dirname ${secretsFile})"
          printf 'relay %s:%s\n' "$username_val" "$password_val" > ${secretsFile}.tmp
          chmod 600 ${secretsFile}.tmp
          mv ${secretsFile}.tmp ${secretsFile}
          systemctl try-restart opensmtpd.service 2>/dev/null || true
        fi
      else
        {
          echo "{ lib, ... }:"
          echo "{"
          echo "  config.mySystem.smtp = lib.mkForce null;"
          echo "}"
        } > ${overridesFile}.tmp
        mv ${overridesFile}.tmp ${overridesFile}
      fi

      rm -f ${pendingFile}

      printf '%s' '{"mode":"current","label":"SMTP settings updated","kind":"smtp"}' > ${sharedRequestFile}.tmp
      mv ${sharedRequestFile}.tmp ${sharedRequestFile}
      touch ${sharedTriggerFile}
    '';
  };

  # While the shared runner is active (or finished within the last
  # couple of minutes), serves its live progress, gated on kind:"smtp"
  # specifically — same cross-flow-bleed fix already applied to
  # dashboard-services.nix and dashboard-network.nix's own statusCgis.
  statusCgi = pkgs.writeShellApplication {
    name = "dashboard-smtp-status-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.findutils ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      progress_kind=""
      if [ -f ${sharedProgressFile} ] && { [ -f ${sharedApplyingFile} ] || [ -n "$(find ${sharedProgressFile} -mmin -2 2>/dev/null)" ]; }; then
        progress_kind=$(jq -r '.kind // empty' ${sharedProgressFile} 2>/dev/null || true)
      fi
      if [ "$progress_kind" = "smtp" ]; then
        build_log=""
        [ -f ${sharedBuildLogFile} ] && build_log=$(tail -n 500 ${sharedBuildLogFile})
        jq --arg buildLog "$build_log" '. + {buildLog: $buildLog}' ${sharedProgressFile}
      elif [ -f ${triggerFile} ] || [ -f ${pendingFile} ]; then
        echo '{"state":"running","message":"Starting...","log":[]}'
      else
        echo '{"state":"idle","message":"","log":[]}'
      fi
    '';
  };

  currentCgi = pkgs.writeShellApplication {
    name = "dashboard-smtp-current-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.gnugrep ];
    text = ''
      ${passwordSetCheckFn}
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      password_set=$(password_already_set)
      jq --argjson passwordSet "$password_set" '. + {passwordSet: $passwordSet}' ${stateJson}
    '';
  };
in
{
  options.mySystem.features.dashboardSmtp.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Dashboard-driven SMTP relay configuration — see
      modules/dashboard-smtp.nix and the "OpenSMTP" accordion on the
      System Preferences page. Saving triggers a real nixos-rebuild
      switch (via modules/system-rebuild.nix's shared runner) pinned to
      the currently-installed release, via a /persist-backed overrides
      file that forces mySystem.smtp as a whole. The password is written
      directly to /persist/etc/opensmtpd/secrets and never passes
      through the overrides file or the Nix store.
    '';
  };

  config = lib.mkIf cfg.enable {
    users.users.dashboard-smtp = {
      isSystemUser = true;
      group = "dashboard-smtp";
      # Lets statusCgi (running as this user) traverse into
      # modules/system-rebuild.nix's shared run directory (0770
      # root:system-rebuild) to read its progress file and check its
      # applying lock.
      extraGroups = [ "system-rebuild" ];
    };
    users.groups.dashboard-smtp = { };

    environment.etc."dashboard-smtp-state.json".source = stateJson;

    systemd.tmpfiles.rules = [
      "d ${runDir} 0750 dashboard-smtp dashboard-smtp - -"
    ];

    # Never wantedBy anything — purely triggered by the path unit below.
    systemd.services.dashboard-smtp-apply = {
      description = "Write SMTP overrides/secrets and hand off to the shared rebuild runner";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe applyScript;
      };
    };
    systemd.paths.dashboard-smtp-apply = {
      description = "Watch for a web-triggered SMTP settings change";
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathExists = triggerFile;
    };

    services.fcgiwrap.instances.dashboard-smtp = {
      process = {
        user = "dashboard-smtp";
        group = "dashboard-smtp";
      };
      socket = {
        user = config.services.nginx.user;
        group = config.services.nginx.group;
      };
    };

    # Rides on the existing dashboard vhost, same shape as
    # modules/dashboard-services.nix. Admin-only throughout: a failed
    # apply's error message could hint at internal state, and this
    # writes real upstream mail credentials.
    services.nginx.virtualHosts.dashboard.locations = {
      "= /preferences/smtp/current" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-smtp.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe currentCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/smtp/save" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-smtp.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe saveCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param CONTENT_TYPE $content_type;
          fastcgi_param CONTENT_LENGTH $content_length;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/smtp/status" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-smtp.sock;
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
