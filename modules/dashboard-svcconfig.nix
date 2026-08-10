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

  # Same shape, for the one Vaultwarden setting genuinely safe to
  # expose — see modules/common.nix's vaultwarden.signupsAllowed option.
  vaultwardenOverridesFile = "/persist/nixos-vaultwarden-overrides.nix";

  # Same shape, for Tailscale's four `tailscale set` toggles — see
  # modules/common.nix's tailscale.accept*/advertise* options.
  tailscaleOverridesFile = "/persist/nixos-tailscale-overrides.nix";

  # Same shape as vaultwardenOverridesFile — each is a single,
  # independent boolean (unlike Tailscale's four fields, these don't
  # need to share one file or fall back to a prior value on partial
  # submission).
  immichMlOverridesFile = "/persist/nixos-immich-ml-overrides.nix";
  immichProxyOverridesFile = "/persist/nixos-immich-proxy-overrides.nix";

  # Absorbed from the now-deleted modules/dashboard-services.nix (the old
  # "Services" accordion on System Preferences) — every service
  # enable/disable flag now lives here instead, one toggle per service's
  # own panel on this page. Order matches this page's category grouping.
  # Not selfUpdate, traefikDns01, or the two dashboard*.enable flags —
  # those were never part of that accordion either.
  flagPaths = [
    [ "jellyfin" "enable" ]
    [ "plex" "enable" ]
    [ "immich" "enable" ]
    [ "minio" "enable" ]
    [ "filebrowser" "enable" ]
    [ "homeAssistant" "enable" ]
    [ "homeAssistant" "zwave" "enable" ]
    [ "homeAssistant" "hacs" "enable" ]
    [ "frigate" "enable" ]
    [ "mediaAcquisition" "enable" ]
    [ "mediaAcquisition" "seerr" "enable" ]
    [ "mediaAcquisition" "radarr" "enable" ]
    [ "mediaAcquisition" "sonarr" "enable" ]
    [ "mediaAcquisition" "jackett" "enable" ]
    [ "mediaAcquisition" "qbittorrent" "enable" ]
    [ "sso" "enable" ]
    [ "sso" "authelia" "enable" ]
    [ "nebula" "enable" ]
    [ "tailscale" "enable" ]
    [ "vaultwarden" "enable" ]
    [ "scrutiny" "enable" ]
  ];
  flagKey = path: lib.concatStringsSep "." path;
  flagVarName = path: lib.replaceStrings [ "." ] [ "_" ] (flagKey path);
  flagKeyCaseArms = lib.concatStringsSep "|" (map flagKey flagPaths);

  # One consolidated file for all 21 — mirrors dashboard-services.nix's
  # own former "one file, full rewrite of every flag" convention, rather
  # than 21 tiny per-flag files.
  serviceEnableOverridesFile = "/persist/nixos-service-enable-overrides.nix";

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
    "vaultwarden.signupsAllowed" = f.vaultwarden.signupsAllowed;
    "tailscale.acceptDns" = f.tailscale.acceptDns;
    "tailscale.acceptRoutes" = f.tailscale.acceptRoutes;
    "tailscale.advertiseExitNode" = f.tailscale.advertiseExitNode;
    "tailscale.advertiseRoutes" = f.tailscale.advertiseRoutes;
    "immich.machineLearning.enable" = f.immich.machineLearning.enable;
    "immich.publicProxy.enable" = f.immich.publicProxy.enable;
  } // lib.listToAttrs (map
    (path: lib.nameValuePair (flagKey path) (lib.getAttrFromPath path f))
    flagPaths);
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
          authelia.theme|minio.rootUser|minio.rootPassword|vaultwarden.signupsAllowed) ;;
          tailscale.acceptDns|tailscale.acceptRoutes|tailscale.advertiseExitNode|tailscale.advertiseRoutes) ;;
          immich.machineLearning.enable|immich.publicProxy.enable) ;;
          ${flagKeyCaseArms}) ;;
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

      if printf '%s' "$body" | jq -e 'has("vaultwarden.signupsAllowed")' >/dev/null 2>&1; then
        signups_val=$(printf '%s' "$body" | jq -r '.["vaultwarden.signupsAllowed"]')
        case "$signups_val" in
          true|false) ;;
          *) fail "invalid vaultwarden.signupsAllowed" ;;
        esac
        request_json=$(printf '%s' "$request_json" | jq --argjson v "$signups_val" '.["vaultwarden.signupsAllowed"] = $v')
      fi

      for field in acceptDns acceptRoutes advertiseExitNode; do
        k="tailscale.$field"
        if printf '%s' "$body" | jq -e --arg k "$k" 'has($k)' >/dev/null 2>&1; then
          v=$(printf '%s' "$body" | jq -r --arg k "$k" '.[$k]')
          case "$v" in
            true|false) ;;
            *) fail "invalid $k" ;;
          esac
          request_json=$(printf '%s' "$request_json" | jq --arg k "$k" --argjson v "$v" '.[$k] = $v')
        fi
      done

      if printf '%s' "$body" | jq -e 'has("tailscale.advertiseRoutes")' >/dev/null 2>&1; then
        routes_val=$(printf '%s' "$body" | jq -r '.["tailscale.advertiseRoutes"]')
        # Charset-restricted (comma-separated CIDRs only) rather than
        # just newline-rejected like minio's fields above — this value
        # gets interpolated straight into a generated Nix source file
        # in applyScript below, so anything outside this charset (a
        # quote, semicolon, brace, backslash, dollar sign...) would be
        # a Nix syntax/injection risk, not just a cosmetic issue.
        case "$routes_val" in
          "") ;;
          *[!0-9a-fA-F:.,/]*) fail "invalid tailscale.advertiseRoutes — use a comma-separated CIDR list" ;;
          ,*|*,|*,,*) fail "invalid tailscale.advertiseRoutes — use a comma-separated CIDR list" ;;
        esac
        request_json=$(printf '%s' "$request_json" | jq --arg v "$routes_val" '.["tailscale.advertiseRoutes"] = $v')
      fi

      for field in "immich.machineLearning.enable" "immich.publicProxy.enable"; do
        if printf '%s' "$body" | jq -e --arg k "$field" 'has($k)' >/dev/null 2>&1; then
          v=$(printf '%s' "$body" | jq -r --arg k "$field" '.[$k]')
          case "$v" in
            true|false) ;;
            *) fail "invalid $field" ;;
          esac
          request_json=$(printf '%s' "$request_json" | jq --arg k "$field" --argjson v "$v" '.[$k] = $v')
        fi
      done

      # Every service enable/disable flag, ported from the old Services
      # accordion's saveCgi — optional per-key here (unlike that old
      # module, which required all 21 on every save), matching how
      # every other field on this page only gets submitted when it
      # actually changed (buildChanges() on the frontend). Server-side
      # group-consistency normalization (sso off forces authelia off,
      # etc.) happens in applyScript below, against the *resolved*
      # value of each flag (submitted-or-last-known), not just what
      # this particular save happened to include.
      ${lib.concatMapStringsSep "\n" (path: ''
        if printf '%s' "$body" | jq -e 'has("${flagKey path}")' >/dev/null 2>&1; then
          v=$(printf '%s' "$body" | jq -r '.["${flagKey path}"]')
          case "$v" in
            true|false) ;;
            *) fail "invalid ${flagKey path}" ;;
          esac
          request_json=$(printf '%s' "$request_json" | jq --argjson v "$v" '.["${flagKey path}"] = $v')
        fi
      '') flagPaths}

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

  # Privileged oneshot, triggered by the path unit below. Independent
  # concerns in one script/one trigger, so a single Save click can
  # change any combination at once: MinIO's credentials are rewritten
  # and the service restarted *synchronously* here (no rebuild
  # involved — modules/minio.nix's rootCredentialsFile is a plain
  # runtime file); Authelia's theme and Vaultwarden's signupsAllowed,
  # if present, each write their own overrides file and share exactly
  # one handoff to modules/system-rebuild.nix's shared runner, NOT
  # waited on here, matching dashboard-services-apply's own
  # fire-and-forget shape.
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

      vaultwarden_present=$(jq -r 'has("vaultwarden.signupsAllowed") | tostring' ${pendingFile})
      if [ "$vaultwarden_present" = "true" ]; then
        signups_val=$(jq -r '.["vaultwarden.signupsAllowed"]' ${pendingFile})
        {
          echo "{ lib, ... }:"
          echo "{"
          echo "  config.mySystem.features.vaultwarden.signupsAllowed = lib.mkForce $signups_val;"
          echo "}"
        } > ${vaultwardenOverridesFile}.tmp
        mv ${vaultwardenOverridesFile}.tmp ${vaultwardenOverridesFile}
      fi

      # Reads a tailscale.* field from this save's payload if present,
      # else falls back to the last-known value from
      # /etc/dashboard-svcconfig-state.json — needed because all four
      # fields share one overrides file, regenerated from scratch on
      # every save. Without this, saving just one changed checkbox
      # would silently reset the other three to their common.nix
      # defaults instead of leaving them as they were.
      tailscale_get_field() {
        local k="$1"
        if jq -e --arg k "$k" 'has($k)' ${pendingFile} >/dev/null 2>&1; then
          jq -r --arg k "$k" '.[$k]' ${pendingFile}
        else
          jq -r --arg k "$k" '.[$k]' /etc/dashboard-svcconfig-state.json
        fi
      }

      tailscale_present=$(jq -r '(has("tailscale.acceptDns") or has("tailscale.acceptRoutes") or has("tailscale.advertiseExitNode") or has("tailscale.advertiseRoutes")) | tostring' ${pendingFile})
      if [ "$tailscale_present" = "true" ]; then
        ts_accept_dns=$(tailscale_get_field "tailscale.acceptDns")
        ts_accept_routes=$(tailscale_get_field "tailscale.acceptRoutes")
        ts_advertise_exit_node=$(tailscale_get_field "tailscale.advertiseExitNode")
        ts_advertise_routes=$(tailscale_get_field "tailscale.advertiseRoutes")
        {
          echo "{ lib, ... }:"
          echo "{"
          echo "  config.mySystem.features.tailscale.acceptDns = lib.mkForce $ts_accept_dns;"
          echo "  config.mySystem.features.tailscale.acceptRoutes = lib.mkForce $ts_accept_routes;"
          echo "  config.mySystem.features.tailscale.advertiseExitNode = lib.mkForce $ts_advertise_exit_node;"
          echo "  config.mySystem.features.tailscale.advertiseRoutes = lib.mkForce \"$ts_advertise_routes\";"
          echo "}"
        } > ${tailscaleOverridesFile}.tmp
        mv ${tailscaleOverridesFile}.tmp ${tailscaleOverridesFile}
      fi

      immich_ml_present=$(jq -r 'has("immich.machineLearning.enable") | tostring' ${pendingFile})
      if [ "$immich_ml_present" = "true" ]; then
        ml_val=$(jq -r '.["immich.machineLearning.enable"]' ${pendingFile})
        {
          echo "{ lib, ... }:"
          echo "{"
          echo "  config.mySystem.features.immich.machineLearning.enable = lib.mkForce $ml_val;"
          echo "}"
        } > ${immichMlOverridesFile}.tmp
        mv ${immichMlOverridesFile}.tmp ${immichMlOverridesFile}
      fi

      immich_proxy_present=$(jq -r 'has("immich.publicProxy.enable") | tostring' ${pendingFile})
      if [ "$immich_proxy_present" = "true" ]; then
        proxy_val=$(jq -r '.["immich.publicProxy.enable"]' ${pendingFile})
        {
          echo "{ lib, ... }:"
          echo "{"
          echo "  config.mySystem.features.immich.publicProxy.enable = lib.mkForce $proxy_val;"
          echo "}"
        } > ${immichProxyOverridesFile}.tmp
        mv ${immichProxyOverridesFile}.tmp ${immichProxyOverridesFile}
      fi

      # Same "read submitted value, else fall back to last-known state"
      # merge tailscale_get_field() already does — all 21 flags share
      # one overrides file, regenerated from scratch on every save, so
      # saving just one changed checkbox must not silently reset the
      # other 20 to their common.nix defaults.
      service_enable_get_field() {
        local k="$1"
        if jq -e --arg k "$k" 'has($k)' ${pendingFile} >/dev/null 2>&1; then
          jq -r --arg k "$k" '.[$k]' ${pendingFile}
        else
          jq -r --arg k "$k" '.[$k]' /etc/dashboard-svcconfig-state.json
        fi
      }

      service_enable_present=$(jq -r '(${lib.concatMapStringsSep " or " (path: "has(\"${flagKey path}\")") flagPaths}) | tostring' ${pendingFile})
      if [ "$service_enable_present" = "true" ]; then
        ${lib.concatMapStringsSep "\n" (path: ''
          ${flagVarName path}=$(service_enable_get_field "${flagKey path}")
        '') flagPaths}

        # Group-consistency normalization against the *resolved* values
        # above, not just what this save happened to submit — same
        # backstop the old Services accordion's saveCgi had server-side,
        # ported here since modules/authelia.nix hard-asserts
        # sso.authelia.enable requires sso.enable, and hitting that
        # assertion mid-rebuild is a much worse failure than never
        # constructing an invalid combination here.
        if [ "$sso_enable" = "false" ]; then
          sso_authelia_enable=false
        fi
        if [ "$homeAssistant_enable" = "false" ]; then
          homeAssistant_zwave_enable=false
          homeAssistant_hacs_enable=false
        fi
        # mediaAcquisition.enable has no UI control on this page (never
        # has) — always written true, matching current production
        # behavior exactly; only its 5 sub-flags are ever really toggled.
        mediaAcquisition_enable=true

        {
          echo "{ lib, ... }:"
          echo "{"
          echo "  config = {"
          ${lib.concatMapStringsSep "\n" (path: ''
            echo "    mySystem.features.${flagKey path} = lib.mkForce ''$${flagVarName path};"
          '') flagPaths}
          echo "  };"
          echo "}"
        } > ${serviceEnableOverridesFile}.tmp
        mv ${serviceEnableOverridesFile}.tmp ${serviceEnableOverridesFile}
      fi

      rm -f ${pendingFile}

      # theme_present/vaultwarden_present/tailscale_present/immich_ml_present/
      # immich_proxy_present/service_enable_present are the rebuild-driven
      # concerns — any one (or several, in the same save) triggers exactly
      # one shared-runner handoff. MinIO's own outcome is already final by
      # this point (synchronous, above); if it failed, surface that
      # directly instead of also kicking off an unrelated rebuild — the
      # overrides file(s) are still written either way, so a pending
      # rebuild-driven change takes effect on whatever rebuild happens
      # next instead of being lost.
      if [ "$theme_present" = "true" ] || [ "$vaultwarden_present" = "true" ] || [ "$tailscale_present" = "true" ] || [ "$immich_ml_present" = "true" ] || [ "$immich_proxy_present" = "true" ] || [ "$service_enable_present" = "true" ]; then
        if [ -n "$minio_result" ] && [ "$minio_result" != "ok" ]; then
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
      modules/dashboard-svcconfig.nix and every service's panel on the
      Service Configuration page (each now carries its own enable/
      disable toggle alongside whatever real settings it has — the
      former "Services" accordion on System Preferences no longer
      exists). One batch save endpoint covering two different
      underlying mechanisms: Authelia's theme, Vaultwarden's
      signupsAllowed, Tailscale's four `tailscale set` toggles,
      Immich's machine-learning/public-proxy toggles, and all 21
      service enable/disable flags each go through their own (or, for
      the 21 flags, one shared) /persist-backed overrides file and
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
