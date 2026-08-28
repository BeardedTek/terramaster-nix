{ config, lib, pkgs, ... }:

let
  f = config.mySystem.features;
  loginEnabled = f.sso.enable;

  # Same lib.mkForce-a-whole-value idiom as every other
  # modules/dashboard-*.nix overrides file — see flake.nix's own
  # usersOverridesPath, which imports this conditionally on
  # builtins.pathExists, same as the rest.
  usersOverridesFile = "/persist/nixos-users-overrides.nix";

  # modules/system-rebuild.nix's own secretsEnv path — a brand-new Unix
  # account needs a real <NAME>_INITIAL_HASH line here before the next
  # rebuild, or modules/users.nix's own assertions fail the build outright.
  secretsEnvFile = "/persist/secrets/initial-passwords.env";

  # The exact file modules/lldap.nix's lldap-seed-initial-passwords.service
  # already watches and consumes on every activation — dropping a new
  # user's plaintext password here needs no new LLDAP-side code at all.
  lldapInitialPasswordsDir = "/persist/etc/lldap/initial-passwords";
  lldapAdminPassFile = "/etc/lldap/ldap_user_pass";
  lldapHttpPort = 17170; # matches modules/lldap.nix's httpPort

  # Samba has no reconciliation service of its own (see
  # modules/samba.nix) — this dir + dashboard-users-seed-samba-passwords
  # below is this module's own equivalent of lldap.nix's seeding service,
  # needed because `smbpasswd -a` requires the Unix account to already
  # exist, which for a brand-new user only becomes true after the rebuild
  # this module triggers has actually landed.
  sambaInitialPasswordsDir = "/persist/etc/samba/initial-passwords";

  runDir = "/run/dashboard-users";
  triggerFile = "${runDir}/trigger";
  pendingFile = "${runDir}/pending.json";

  # Separate run dir/trigger from the add/modify/remove flow above: a
  # password reset never touches a NixOS rebuild (it's three synchronous
  # local operations — chpasswd, an LLDAP API call, smbpasswd), so it must
  # not share a trigger with the shared-rebuild-runner-bound flow above,
  # same reasoning modules/dashboard-svcconfig.nix's MinIO-vs-rebuild split
  # already established.
  resetRunDir = "/run/dashboard-users-reset";
  resetTriggerFile = "${resetRunDir}/trigger";
  resetPendingFile = "${resetRunDir}/pending.json";
  resetResultFile = "${resetRunDir}/result.json";

  sharedRunDir = "/run/system-rebuild";
  sharedRequestFile = "${sharedRunDir}/request.json";
  sharedTriggerFile = "${sharedRunDir}/trigger";
  sharedProgressFile = "${sharedRunDir}/progress.json";
  sharedBuildLogFile = "${sharedRunDir}/build.log";
  sharedApplyingFile = "${sharedRunDir}/applying";

  # Read by currentCgi and by saveCgi's own uniqueness/last-admin checks —
  # same "bake config.mySystem.* into /etc as of the last rebuild" shape as
  # modules/dashboard-svcconfig.nix's own stateJson/currentState.
  usersStateJson = pkgs.writeText "dashboard-users-state.json" (builtins.toJSON {
    users = map (u: { inherit (u) name wheel; }) config.mySystem.users;
  });

  currentCgi = pkgs.writeShellApplication {
    name = "dashboard-users-current-cgi";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      cat /etc/dashboard-users-state.json
    '';
  };

  # Add/modify(wheel)/remove — all three funnel through one endpoint,
  # keyed by "action", same as how svcconfig's saveCgi accepts a batch of
  # differently-shaped fields in one POST.
  saveCgi = pkgs.writeShellApplication {
    name = "dashboard-users-save-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils ];
    text = ''
      body=""
      if [ -n "''${CONTENT_LENGTH:-}" ] && [ "$CONTENT_LENGTH" -gt 0 ]; then
        body=$(head -c "$CONTENT_LENGTH")
      fi

      fail() {
        printf 'Status: 400 Bad Request\r\nContent-Type: application/json\r\n\r\n{"error":"%s"}\n' "$1"
        exit 0
      }

      action=$(printf '%s' "$body" | jq -r '.action // empty' 2>/dev/null || true)
      case "$action" in
        add|modify|remove) ;;
        *) fail "invalid action" ;;
      esac

      name=$(printf '%s' "$body" | jq -r '.name // empty' 2>/dev/null || true)
      # Same username rule the installer wizard already enforces
      # (hosts/installer/wizard/stages/50-users.sh) — kept identical so a
      # name accepted here is guaranteed to also be a valid Nix
      # attribute-free string safe to interpolate straight into the
      # generated overrides file below (no quotes/semicolons/braces
      # possible in this charset).
      case "$name" in
        "") fail "name is required" ;;
        *[!a-z0-9_-]*) fail "invalid username" ;;
      esac
      case "$name" in
        [a-z_]*) ;;
        *) fail "invalid username" ;;
      esac

      existing_count=$(jq -c --arg n "$name" '[.users[] | select(.name == $n)] | length' /etc/dashboard-users-state.json)
      current_wheel_count=$(jq '[.users[] | select(.wheel == true)] | length' /etc/dashboard-users-state.json)
      target_is_wheel=$(jq -r --arg n "$name" '(.users[] | select(.name == $n) | .wheel) // false' /etc/dashboard-users-state.json)

      if [ "$action" = "add" ]; then
        if [ "$existing_count" != "0" ]; then
          fail "a user named \"$name\" already exists"
        fi
        # id (coreutils) resolves via the same libc NSS the rest of the
        # system uses — no separate `getent` binary needed on PATH
        # (confirmed the hard way elsewhere in this repo, see
        # modules/minio.nix's own getent/PATH comment; `id` doesn't hit
        # that problem since it never shells out to a second binary).
        if id "$name" >/dev/null 2>&1; then
          fail "\"$name\" is already a system account"
        fi
        password=$(printf '%s' "$body" | jq -r '.password // empty' 2>/dev/null || true)
        case "$password" in
          "") fail "password is required" ;;
          *$'\n'*) fail "invalid password" ;;
        esac
        wheel=$(printf '%s' "$body" | jq -r '.wheel // false' 2>/dev/null || true)
        case "$wheel" in
          true|false) ;;
          *) fail "invalid wheel value" ;;
        esac
        request_json=$(jq -n --arg action "$action" --arg name "$name" --arg password "$password" --argjson wheel "$wheel" \
          '{action:$action, name:$name, password:$password, wheel:$wheel}')

      elif [ "$action" = "modify" ]; then
        if [ "$existing_count" = "0" ]; then
          fail "no such user: $name"
        fi
        wheel=$(printf '%s' "$body" | jq -r '.wheel // empty' 2>/dev/null || true)
        case "$wheel" in
          true|false) ;;
          *) fail "invalid wheel value" ;;
        esac
        # Mirrors the installer wizard's own "no admin user" guard
        # (stage_50_users' have_wheel check) — there it's an interactive
        # confirmation, but nothing here is interactive, so this has to
        # be a hard refusal instead of a warning: taking the last wheel
        # user off wheel would leave the box with no way to sudo at all.
        if [ "$target_is_wheel" = "true" ] && [ "$wheel" = "false" ] && [ "$current_wheel_count" -le 1 ]; then
          fail "cannot remove admin access from the last admin (wheel) user"
        fi
        request_json=$(jq -n --arg action "$action" --arg name "$name" --argjson wheel "$wheel" \
          '{action:$action, name:$name, wheel:$wheel}')

      else
        if [ "$existing_count" = "0" ]; then
          fail "no such user: $name"
        fi
        if [ "$target_is_wheel" = "true" ] && [ "$current_wheel_count" -le 1 ]; then
          fail "cannot remove the last admin (wheel) user"
        fi
        request_json=$(jq -n --arg action "$action" --arg name "$name" '{action:$action, name:$name}')
      fi

      mkdir -p ${runDir}
      printf '%s' "$request_json" > ${pendingFile}.tmp
      mv ${pendingFile}.tmp ${pendingFile}
      touch ${triggerFile}
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n{"ok":true}\n'
    '';
  };

  # Root-privileged, triggered by the path unit below — same shape as
  # dashboard-svcconfig-apply. Recomputes the *full* desired
  # mySystem.users list from /etc/dashboard-users-state.json (the
  # as-of-last-rebuild baseline) plus this one change, same
  # "regenerate the whole overrides file from scratch every time" idiom
  # svcconfig's own multi-field overrides files (tailscale,
  # service-enable) already use.
  applyScript = pkgs.writeShellApplication {
    name = "dashboard-users-apply";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.mkpasswd pkgs.gnugrep ];
    text = ''
      rm -f ${triggerFile}
      if [ ! -f ${pendingFile} ]; then
        exit 0
      fi

      action=$(jq -r '.action' ${pendingFile})
      name=$(jq -r '.name' ${pendingFile})
      current_users=$(jq -c '.users' /etc/dashboard-users-state.json)

      case "$action" in
        add)
          wheel=$(jq -r '.wheel' ${pendingFile})
          password=$(jq -r '.password' ${pendingFile})
          name_upper=$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]')
          hash=$(mkpasswd -m sha-512 "$password")

          mkdir -p "$(dirname ${secretsEnvFile})"
          touch ${secretsEnvFile}
          { grep -v "^''${name_upper}_INITIAL_HASH=" ${secretsEnvFile} || true; \
            printf "%s_INITIAL_HASH='%s'\n" "$name_upper" "$hash"; \
          } > ${secretsEnvFile}.tmp
          mv ${secretsEnvFile}.tmp ${secretsEnvFile}
          chmod 600 ${secretsEnvFile}

          mkdir -p ${lldapInitialPasswordsDir}
          printf '%s' "$password" > "${lldapInitialPasswordsDir}/$name"
          chmod 600 "${lldapInitialPasswordsDir}/$name"

          mkdir -p ${sambaInitialPasswordsDir}
          printf '%s' "$password" > "${sambaInitialPasswordsDir}/$name"
          chmod 600 "${sambaInitialPasswordsDir}/$name"

          new_users=$(printf '%s' "$current_users" | jq -c --arg name "$name" --argjson wheel "$wheel" \
            '. + [{name:$name, wheel:$wheel}]')
          ;;
        modify)
          wheel=$(jq -r '.wheel' ${pendingFile})
          new_users=$(printf '%s' "$current_users" | jq -c --arg name "$name" --argjson wheel "$wheel" \
            'map(if .name == $name then .wheel = $wheel else . end)')
          ;;
        remove)
          new_users=$(printf '%s' "$current_users" | jq -c --arg name "$name" \
            'map(select(.name != $name))')
          ;;
        *)
          rm -f ${pendingFile}
          exit 0
          ;;
      esac

      rm -f ${pendingFile}

      {
        echo "{ lib, ... }:"
        echo "{"
        echo "  config.mySystem.users = lib.mkForce ["
        printf '%s' "$new_users" | jq -r '.[] | "    { name = \"" + .name + "\"; wheel = " + (.wheel | tostring) + "; }"'
        echo "  ];"
        echo "}"
      } > ${usersOverridesFile}.tmp
      mv ${usersOverridesFile}.tmp ${usersOverridesFile}

      printf '%s' '{"mode":"current","label":"User changes applied","kind":"users"}' > ${sharedRequestFile}.tmp
      mv ${sharedRequestFile}.tmp ${sharedRequestFile}
      touch ${sharedTriggerFile}
    '';
  };

  # This module's own counterpart to modules/lldap.nix's
  # lldap-seed-initial-passwords.service — re-run on every activation, no
  # ConditionPathExists guard, naturally idempotent (each file is deleted
  # right after a successful smbpasswd call). Only picks up a file once
  # `id` resolves the account, i.e. once the rebuild that created it has
  # actually landed — smbpasswd itself doesn't need smbd running, it edits
  # the local tdbsam passdb directly, so no service ordering dependency is
  # needed beyond the Unix account existing.
  seedSambaPasswordsScript = pkgs.writeShellApplication {
    name = "dashboard-users-seed-samba-passwords";
    runtimeInputs = [ pkgs.coreutils pkgs.samba ];
    text = ''
      dir="${sambaInitialPasswordsDir}"
      [ -d "$dir" ] || exit 0
      shopt -s nullglob
      files=("$dir"/*)
      [ "''${#files[@]}" -eq 0 ] && exit 0
      for f in "''${files[@]}"; do
        user="$(basename "$f")"
        if id "$user" >/dev/null 2>&1; then
          password="$(cat "$f")"
          printf '%s\n%s\n' "$password" "$password" | smbpasswd -a -s "$user" >/dev/null 2>&1 || true
          rm -f "$f"
        fi
      done
    '';
  };

  resetPasswordCgi = pkgs.writeShellApplication {
    name = "dashboard-users-reset-password-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils ];
    text = ''
      body=""
      if [ -n "''${CONTENT_LENGTH:-}" ] && [ "$CONTENT_LENGTH" -gt 0 ]; then
        body=$(head -c "$CONTENT_LENGTH")
      fi

      fail() {
        printf 'Status: 400 Bad Request\r\nContent-Type: application/json\r\n\r\n{"error":"%s"}\n' "$1"
        exit 0
      }

      name=$(printf '%s' "$body" | jq -r '.name // empty' 2>/dev/null || true)
      case "$name" in
        "") fail "name is required" ;;
        *[!a-z0-9_-]*) fail "invalid username" ;;
      esac
      case "$name" in
        [a-z_]*) ;;
        *) fail "invalid username" ;;
      esac

      existing_count=$(jq -c --arg n "$name" '[.users[] | select(.name == $n)] | length' /etc/dashboard-users-state.json)
      if [ "$existing_count" = "0" ]; then
        fail "no such user: $name"
      fi

      password=$(printf '%s' "$body" | jq -r '.password // empty' 2>/dev/null || true)
      case "$password" in
        "") fail "password is required" ;;
        *$'\n'*) fail "invalid password" ;;
      esac

      request_json=$(jq -n --arg name "$name" --arg password "$password" '{name:$name, password:$password}')

      mkdir -p ${resetRunDir}
      printf '%s' "$request_json" > ${resetPendingFile}.tmp
      mv ${resetPendingFile}.tmp ${resetPendingFile}
      rm -f ${resetResultFile}
      touch ${resetTriggerFile}
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n{"ok":true}\n'
    '';
  };

  # Root-privileged, triggered by its own path unit — three independent
  # local operations, no rebuild involved, so this stays synchronous and
  # fast rather than going through modules/system-rebuild.nix's shared
  # runner (same "MinIO doesn't need a rebuild either" reasoning
  # dashboard-svcconfig.nix's own applyScript already established).
  resetApplyScript = pkgs.writeShellApplication {
    name = "dashboard-users-reset-apply";
    runtimeInputs = [ pkgs.jq pkgs.jo pkgs.curl pkgs.coreutils pkgs.lldap pkgs.samba pkgs.shadow ];
    text = ''
      rm -f ${resetTriggerFile}
      if [ ! -f ${resetPendingFile} ]; then
        exit 0
      fi

      name=$(jq -r '.name' ${resetPendingFile})
      password=$(jq -r '.password' ${resetPendingFile})
      rm -f ${resetPendingFile}

      unix_result="ok"
      if ! printf '%s:%s\n' "$name" "$password" | chpasswd; then
        unix_result="error: failed to set Unix password"
      fi

      # Same admin-token-then-lldap_set_password call
      # modules/lldap.nix's own seedInitialPasswordsScript already proved
      # out, just aimed at one named user instead of iterating pending
      # files.
      lldap_result="ok"
      admin_password="$(cat ${lldapAdminPassFile} 2>/dev/null || echo "")"
      if [ -z "$admin_password" ]; then
        lldap_result="error: LLDAP admin credential not available"
      else
        token="$(curl --silent --request POST --url "http://127.0.0.1:${toString lldapHttpPort}/auth/simple/login" \
          --header 'Content-Type: application/json' \
          --data "$(jo -- username=admin password="$admin_password")" \
          | jq --raw-output .token)"
        if [ -z "$token" ] || [ "$token" = "null" ]; then
          lldap_result="error: could not authenticate to LLDAP"
        elif ! lldap_set_password --base-url "http://127.0.0.1:${toString lldapHttpPort}" --token "$token" \
          --username "$name" --password "$password"; then
          lldap_result="error: failed to set LLDAP password"
        fi
      fi

      samba_result="ok"
      if ! (printf '%s\n%s\n' "$password" "$password" | smbpasswd -a -s "$name"); then
        samba_result="error: failed to set Samba password"
      fi

      jq -n --arg unix "$unix_result" --arg lldap "$lldap_result" --arg samba "$samba_result" \
        '{state: (if $unix == "ok" and $lldap == "ok" and $samba == "ok" then "success" else "failed" end),
          message: ([$unix, $lldap, $samba] | map(select(. != "ok")) | if length == 0 then "Password reset for all systems" else join("; ") end),
          unix: $unix, lldap: $lldap, samba: $samba}' > ${resetResultFile}
    '';
  };

  # Dual-path, same shape as dashboard-svcconfig.nix's own statusCgi: a
  # fresh local result.json (the reset-password, no-rebuild path) takes
  # priority; otherwise falls through to the shared runner's kind:"users"
  # progress for the add/modify/remove path.
  statusCgi = pkgs.writeShellApplication {
    name = "dashboard-users-status-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.findutils ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      if [ -f ${resetResultFile} ] && [ -n "$(find ${resetResultFile} -mmin -2 2>/dev/null)" ]; then
        cat ${resetResultFile}
        exit 0
      fi

      progress_kind=""
      if [ -f ${sharedProgressFile} ] && { [ -f ${sharedApplyingFile} ] || [ -n "$(find ${sharedProgressFile} -mmin -2 2>/dev/null)" ]; }; then
        progress_kind=$(jq -r '.kind // empty' ${sharedProgressFile} 2>/dev/null || true)
      fi
      if [ "$progress_kind" = "users" ]; then
        build_log=""
        [ -f ${sharedBuildLogFile} ] && build_log=$(tail -n 500 ${sharedBuildLogFile})
        jq --arg buildLog "$build_log" '. + {buildLog: $buildLog}' ${sharedProgressFile}
      elif [ -f ${triggerFile} ] || [ -f ${pendingFile} ] || [ -f ${resetTriggerFile} ] || [ -f ${resetPendingFile} ]; then
        echo '{"state":"running","message":"Starting...","log":[]}'
      else
        echo '{"state":"idle","message":"","log":[]}'
      fi
    '';
  };
in
{
  config = lib.mkIf loginEnabled {
    users.users.dashboard-users = {
      isSystemUser = true;
      group = "dashboard-users";
      # Lets statusCgi (running as this user) read
      # modules/system-rebuild.nix's shared run directory (0770
      # root:system-rebuild), same as dashboard-svcconfig's own grant.
      extraGroups = [ "system-rebuild" ];
    };
    users.groups.dashboard-users = { };

    environment.etc."dashboard-users-state.json".source = usersStateJson;

    systemd.tmpfiles.rules = [
      "d ${runDir} 0750 dashboard-users dashboard-users - -"
      "d ${resetRunDir} 0750 dashboard-users dashboard-users - -"
      "d ${lldapInitialPasswordsDir} 0700 root root - -"
      "d ${sambaInitialPasswordsDir} 0700 root root - -"
    ];

    # Never wantedBy anything — purely triggered by the path unit below,
    # same shape as dashboard-svcconfig-apply.
    systemd.services.dashboard-users-apply = {
      description = "Apply an add/modify/remove change from the dashboard's Users page";
      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe applyScript;
      };
    };
    systemd.paths.dashboard-users-apply = {
      description = "Watch for a web-submitted user add/modify/remove change";
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathExists = triggerFile;
    };

    systemd.services.dashboard-users-reset-apply = {
      description = "Apply a password reset from the dashboard's Users page (Unix + LLDAP + Samba)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe resetApplyScript;
      };
    };
    systemd.paths.dashboard-users-reset-apply = {
      description = "Watch for a web-submitted password reset";
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathExists = resetTriggerFile;
    };

    systemd.services.dashboard-users-seed-samba-passwords = {
      description = "Seed initial Samba passwords for dashboard-created users, one time only";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe seedSambaPasswordsScript;
      };
    };

    services.fcgiwrap.instances.dashboard-users = {
      process = {
        user = "dashboard-users";
        group = "dashboard-users";
      };
      socket = {
        user = config.services.nginx.user;
        group = config.services.nginx.group;
      };
    };

    # Rides on the existing dashboard vhost, same shape as every other
    # preferences module. Admin-only throughout.
    services.nginx.virtualHosts.dashboard.locations = {
      "= /preferences/users/current" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-users.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe currentCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/users/save" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-users.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe saveCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param CONTENT_TYPE $content_type;
          fastcgi_param CONTENT_LENGTH $content_length;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/users/reset-password" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-users.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe resetPasswordCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param CONTENT_TYPE $content_type;
          fastcgi_param CONTENT_LENGTH $content_length;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/users/status" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-users.sock;
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
