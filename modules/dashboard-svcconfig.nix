{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.dashboardSvcconfig;
  f = config.mySystem.features;

  loginEnabled = f.sso.enable;

  # Same /persist-backed overrides shape as dashboard-smtp.nix — forces
  # the one Authelia setting genuinely safe to expose (see
  # modules/common.nix's sso.authelia.theme option for why the rest of
  # modules/authelia.nix stays hardcoded).
  overridesFile = "/persist/nixos-authelia-overrides.nix";

  # The literal path modules/minio.nix's rootCredentialsFile already
  # points at — a plain runtime secrets file (systemd EnvironmentFile=),
  # not baked into the Nix store, so rewriting it only needs a service
  # restart, never a rebuild.
  minioEnvFile = "/etc/minio/minio.env";

  runDir = "/run/dashboard-svcconfig";
  triggerFile = "${runDir}/trigger";
  pendingFile = "${runDir}/pending.json";
  resultFile = "${runDir}/result.json";

  sharedRunDir = "/run/system-rebuild";
  sharedRequestFile = "${sharedRunDir}/request.json";
  sharedTriggerFile = "${sharedRunDir}/trigger";
  sharedProgressFile = "${sharedRunDir}/progress.json";
  sharedBuildLogFile = "${sharedRunDir}/build.log";
  sharedApplyingFile = "${sharedRunDir}/applying";

  currentState = {
    "authelia.theme" = f.sso.authelia.theme;
  };
  stateJson = pkgs.writeText "dashboard-svcconfig-state.json" (builtins.toJSON currentState);

  # Shared by saveCgi (blank/absent password = keep whatever's already
  # there) and currentCgi (report that fact as a boolean, never the
  # value) — same shape as dashboard-smtp.nix's passwordSetCheckFn, just
  # reading MinIO's own env-file format instead of the OpenSMTPD secrets
  # table. secrets/extra-files/persist/etc/minio/minio.env.example ships
  # a literal change-me placeholder for MINIO_ROOT_PASSWORD.
  minioHelpersFn = ''
    minio_current_user() {
      if [ -f ${minioEnvFile} ]; then
        while IFS= read -r line || [ -n "$line" ]; do
          case "$line" in
            MINIO_ROOT_USER=*)
              val="''${line#MINIO_ROOT_USER=}"
              # Strip one layer of matching quotes if present — the
              # shipped .example file quotes its values; this module
              # always writes unquoted going forward (systemd's
              # EnvironmentFile= accepts both), but a pre-existing file
              # may still be quoted.
              val="''${val%\"}"; val="''${val#\"}"
              val="''${val%\'}"; val="''${val#\'}"
              printf '%s' "$val"
              return 0
              ;;
          esac
        done < ${minioEnvFile}
      fi
      printf '%s' ""
    }

    minio_password_already_set() {
      if [ -f ${minioEnvFile} ] && grep -q '^MINIO_ROOT_PASSWORD=' ${minioEnvFile} \
        && ! grep -qi 'change-me' <(grep '^MINIO_ROOT_PASSWORD=' ${minioEnvFile}); then
        echo true
      else
        echo false
      fi
    }
  '';

  saveCgi = pkgs.writeShellApplication {
    name = "dashboard-svcconfig-save-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.gnugrep ];
    text = ''
      ${minioHelpersFn}

      body=""
      if [ -n "''${CONTENT_LENGTH:-}" ] && [ "$CONTENT_LENGTH" -gt 0 ]; then
        body=$(head -c "$CONTENT_LENGTH")
      fi

      fail() {
        printf 'Status: 400 Bad Request\r\nContent-Type: application/json\r\n\r\n{"error":"%s"}\n' "$1"
        exit 0
      }

      keys=$(printf '%s' "$body" | jq -r 'keys[]' 2>/dev/null) || fail "invalid JSON"
      case "$keys" in
        "") fail "no changes submitted" ;;
      esac
      while IFS= read -r k; do
        [ -z "$k" ] && continue
        case "$k" in
          authelia.theme|minio.rootUser|minio.rootPassword) ;;
          *) fail "unknown field: $k" ;;
        esac
      done <<< "$keys"

      request_json="{}"

      if printf '%s' "$body" | jq -e 'has("authelia.theme")' >/dev/null 2>&1; then
        theme_val=$(printf '%s' "$body" | jq -r '.["authelia.theme"]')
        case "$theme_val" in
          light|dark|auto) ;;
          *) fail "invalid authelia.theme" ;;
        esac
        request_json=$(printf '%s' "$request_json" | jq --arg v "$theme_val" '.["authelia.theme"] = $v')
      fi

      minio_user_present=false
      pass_val=""
      if printf '%s' "$body" | jq -e 'has("minio.rootUser")' >/dev/null 2>&1; then
        minio_user_present=true
        user_val=$(printf '%s' "$body" | jq -r '.["minio.rootUser"]')
        case "$user_val" in
          "") fail "minio.rootUser is required if present" ;;
        esac
        case "$user_val" in
          *$'\n'*) fail "invalid minio.rootUser" ;;
        esac
        request_json=$(printf '%s' "$request_json" | jq --arg v "$user_val" '.["minio.rootUser"] = $v')
      fi
      if printf '%s' "$body" | jq -e 'has("minio.rootPassword")' >/dev/null 2>&1; then
        pass_val=$(printf '%s' "$body" | jq -r '.["minio.rootPassword"]')
        case "$pass_val" in
          *$'\n'*) fail "invalid minio.rootPassword" ;;
        esac
        request_json=$(printf '%s' "$request_json" | jq --arg v "$pass_val" '.["minio.rootPassword"] = $v')
      fi
      # Applies regardless of whether minio.rootPassword was submitted
      # at all — a rootUser-only payload (key absent entirely) must
      # fail here too if no real password exists yet, not just a
      # rootUser-plus-blank-password one. Checked once, after both keys
      # are parsed, rather than nested inside the has("minio.rootPassword")
      # branch above where an absent key would skip it entirely.
      if [ "$minio_user_present" = "true" ] && [ -z "$pass_val" ]; then
        password_set=$(minio_password_already_set)
        if [ "$password_set" = "false" ]; then
          fail "a password is required — none is set yet"
        fi
      fi

      mkdir -p ${runDir}
      printf '%s' "$request_json" > ${pendingFile}.tmp
      mv ${pendingFile}.tmp ${pendingFile}
      rm -f ${resultFile}
      touch ${triggerFile}
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n{"ok":true}\n'
    '';
  };

  # Privileged oneshot, triggered by the path unit below. Two
  # independent concerns in one script/one trigger, so a single Save
  # click can change both at once: MinIO's credentials are rewritten
  # and the service restarted *synchronously* here (no rebuild
  # involved — modules/minio.nix's rootCredentialsFile is a plain
  # runtime file); Authelia's theme, if present, is handed off to
  # modules/system-rebuild.nix's shared runner and NOT waited on here,
  # matching dashboard-services-apply's own fire-and-forget shape.
  applyScript = pkgs.writeShellApplication {
    name = "dashboard-svcconfig-apply";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.systemd pkgs.gnugrep ];
    text = ''
      rm -f ${triggerFile}

      if [ ! -f ${pendingFile} ]; then
        exit 0
      fi

      write_local_result() {
        local outcome="$1"
        if [ "$outcome" = "ok" ]; then
          jq -n '{state:"success", message:"Service configuration updated", kind:"svcconfig", log:[]}' > ${resultFile}
        else
          jq -n --arg msg "$outcome" '{state:"failed", message:$msg, kind:"svcconfig", log:[]}' > ${resultFile}
        fi
      }

      minio_present=$(jq -r '(has("minio.rootUser") or has("minio.rootPassword")) | tostring' ${pendingFile})
      minio_result=""
      if [ "$minio_present" = "true" ]; then
        new_user=$(jq -r '.["minio.rootUser"] // empty' ${pendingFile})
        new_pass=$(jq -r '.["minio.rootPassword"] // empty' ${pendingFile})

        mkdir -p "$(dirname ${minioEnvFile})"
        {
          wrote_user=false
          wrote_pass=false
          if [ -f ${minioEnvFile} ]; then
            while IFS= read -r line || [ -n "$line" ]; do
              case "$line" in
                MINIO_ROOT_USER=*)
                  if [ -n "$new_user" ]; then
                    printf 'MINIO_ROOT_USER=%s\n' "$new_user"
                  else
                    printf '%s\n' "$line"
                  fi
                  wrote_user=true
                  ;;
                MINIO_ROOT_PASSWORD=*)
                  if [ -n "$new_pass" ]; then
                    printf 'MINIO_ROOT_PASSWORD=%s\n' "$new_pass"
                  else
                    printf '%s\n' "$line"
                  fi
                  wrote_pass=true
                  ;;
                *)
                  # Passed through byte-for-byte untouched — this is what
                  # protects MINIO_IDENTITY_OPENID_CLIENT_SECRET (see
                  # modules/minio.nix's rootCredentialsFile comment) from
                  # ever being clobbered by this writer.
                  printf '%s\n' "$line"
                  ;;
              esac
            done < ${minioEnvFile}
          fi
          if [ "$wrote_user" = "false" ] && [ -n "$new_user" ]; then
            printf 'MINIO_ROOT_USER=%s\n' "$new_user"
          fi
          if [ "$wrote_pass" = "false" ] && [ -n "$new_pass" ]; then
            printf 'MINIO_ROOT_PASSWORD=%s\n' "$new_pass"
          fi
        } > ${minioEnvFile}.tmp
        mv ${minioEnvFile}.tmp ${minioEnvFile}
        chown root:dashboard-svcconfig ${minioEnvFile}
        chmod 640 ${minioEnvFile}

        # mySystem.features.minio.enable being off means the unit simply
        # doesn't exist yet — not a failure, same posture as
        # dashboard-nebula-apply's own restart guard.
        if ! systemctl cat minio.service >/dev/null 2>&1; then
          minio_result="ok"
        elif systemctl restart minio.service && systemctl is-active --quiet minio.service; then
          minio_result="ok"
        else
          minio_result="error: minio failed to restart — check journalctl -u minio"
        fi
      fi

      theme_present=$(jq -r 'has("authelia.theme") | tostring' ${pendingFile})
      if [ "$theme_present" = "true" ]; then
        theme_val=$(jq -r '.["authelia.theme"]' ${pendingFile})
        {
          echo "{ lib, ... }:"
          echo "{"
          echo "  config.mySystem.features.sso.authelia.theme = lib.mkForce \"$theme_val\";"
          echo "}"
        } > ${overridesFile}.tmp
        mv ${overridesFile}.tmp ${overridesFile}
      fi

      rm -f ${pendingFile}

      if [ "$theme_present" = "true" ]; then
        if [ -n "$minio_result" ] && [ "$minio_result" != "ok" ]; then
          # Something already went wrong — report that directly rather
          # than also kicking off an unrelated rebuild. The overrides
          # file is still written, so the theme change takes effect on
          # whatever rebuild happens next instead of being lost.
          write_local_result "$minio_result"
        else
          printf '%s' '{"mode":"current","label":"Service configuration updated","kind":"svcconfig"}' > ${sharedRequestFile}.tmp
          mv ${sharedRequestFile}.tmp ${sharedRequestFile}
          touch ${sharedTriggerFile}
        fi
      elif [ "$minio_present" = "true" ]; then
        write_local_result "$minio_result"
      else
        write_local_result "error: nothing to apply"
      fi
    '';
  };

  # Fresh local result.json (the MinIO-only, no-rebuild path) takes
  # priority; otherwise falls through to the shared runner's
  # kind:"svcconfig" progress, exactly like every other caller's own
  # statusCgi. One response contract either way — the frontend never
  # needs to know which path actually ran.
  statusCgi = pkgs.writeShellApplication {
    name = "dashboard-svcconfig-status-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.findutils ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      if [ -f ${resultFile} ] && [ -n "$(find ${resultFile} -mmin -2 2>/dev/null)" ]; then
        cat ${resultFile}
        exit 0
      fi

      progress_kind=""
      if [ -f ${sharedProgressFile} ] && { [ -f ${sharedApplyingFile} ] || [ -n "$(find ${sharedProgressFile} -mmin -2 2>/dev/null)" ]; }; then
        progress_kind=$(jq -r '.kind // empty' ${sharedProgressFile} 2>/dev/null || true)
      fi
      if [ "$progress_kind" = "svcconfig" ]; then
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
    name = "dashboard-svcconfig-current-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.gnugrep ];
    text = ''
      ${minioHelpersFn}
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      minio_user=$(minio_current_user)
      minio_pass_set=$(minio_password_already_set)
      jq -n --slurpfile state ${stateJson} --arg user "$minio_user" --argjson passSet "$minio_pass_set" \
        '$state[0] + {"minio.rootUser": $user, "minio.rootPasswordSet": $passSet}'
    '';
  };
in
{
  options.mySystem.features.dashboardSvcconfig.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Dashboard-driven Service Configuration save pipeline — see
      modules/dashboard-svcconfig.nix and the Authelia/MinIO blocks on
      the Service Configuration page. One batch save endpoint covering
      two different underlying mechanisms: Authelia's theme goes
      through a /persist-backed overrides file and
      modules/system-rebuild.nix's shared rebuild runner (kind:
      "svcconfig"); MinIO's root credentials are rewritten directly
      into modules/minio.nix's rootCredentialsFile and the service
      restarted, no rebuild involved.
    '';
  };

  config = lib.mkIf cfg.enable {
    users.users.dashboard-svcconfig = {
      isSystemUser = true;
      group = "dashboard-svcconfig";
      # Lets statusCgi (running as this user) traverse into
      # modules/system-rebuild.nix's shared run directory (0770
      # root:system-rebuild) to read its progress file and check its
      # applying lock.
      extraGroups = [ "system-rebuild" ];
    };
    users.groups.dashboard-svcconfig = { };

    environment.etc."dashboard-svcconfig-state.json".source = stateJson;

    systemd.tmpfiles.rules = [
      "d ${runDir} 0750 dashboard-svcconfig dashboard-svcconfig - -"
      # Fixes ownership/permissions on every boot — a minio.env
      # delivered before this feature existed (600 root:root, the
      # typical out-of-repo secrets-delivery default) would otherwise
      # never get upgraded on its own, same class of migration fix as
      # modules/dashboard-nebula.nix's own config-file `z` rule.
      "z ${minioEnvFile} 0640 root dashboard-svcconfig - -"
    ];

    # Never wantedBy anything — purely triggered by the path unit below.
    systemd.services.dashboard-svcconfig-apply = {
      description = "Apply a batch of Service Configuration changes (Authelia theme / MinIO credentials)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe applyScript;
      };
    };
    systemd.paths.dashboard-svcconfig-apply = {
      description = "Watch for a web-submitted Service Configuration change";
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathExists = triggerFile;
    };

    services.fcgiwrap.instances.dashboard-svcconfig = {
      process = {
        user = "dashboard-svcconfig";
        group = "dashboard-svcconfig";
      };
      socket = {
        user = config.services.nginx.user;
        group = config.services.nginx.group;
      };
    };

    # Rides on the existing dashboard vhost, same shape as every other
    # preferences module. Admin-only throughout — this handles MinIO's
    # root password.
    services.nginx.virtualHosts.dashboard.locations = {
      "= /preferences/svcconfig/current" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-svcconfig.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe currentCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/svcconfig/save" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-svcconfig.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe saveCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param CONTENT_TYPE $content_type;
          fastcgi_param CONTENT_LENGTH $content_length;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/svcconfig/status" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-svcconfig.sock;
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
