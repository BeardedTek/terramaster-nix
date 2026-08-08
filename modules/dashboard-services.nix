{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.dashboardServices;
  hostName = config.networking.hostName;
  f = config.mySystem.features;

  loginEnabled = config.mySystem.features.sso.enable;

  repo = "BeardedTek/terramaster-nix";
  apiLatest = "https://api.github.com/repos/${repo}/releases/latest";

  versionFile = "/persist/nixos-version";
  secretsEnv = "/persist/secrets/initial-passwords.env";
  overridesFile = "/persist/nixos-service-overrides.nix";
  stagingDir = "/persist/nixos-dashboard-services-staging";

  runDir = "/run/dashboard-services";
  triggerFile = "${runDir}/trigger";
  pendingFile = "${runDir}/pending.json";
  progressFile = "${runDir}/progress.json";
  buildLogFile = "${runDir}/build.log";
  applyingFile = "${runDir}/applying";
  selfUpdateApplyingFile = "/run/nas-update/applying";

  # Every flag the Services accordion can toggle — the single source of
  # truth this whole module works from. Order matches
  # dashboard/content/preferences.md's grouping (Design decision 7 of the
  # plan this module implements): Media Playback / Storage / Home
  # Automation / Media Acquisition / Authentication. Not selfUpdate,
  # nebula, or traefikDns01 — those aren't represented in this accordion.
  flagPaths = [
    [ "jellyfin" "enable" ]
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
  ];

  flagKey = path: lib.concatStringsSep "." path;

  # Build-time snapshot of what's actually running right now, regardless
  # of whether it came from variables.nix or a previously-saved
  # overrides file — same "one file computes, another consumes" shape
  # mySystem.serviceBackends/mySystem.sso.protectedServices already use
  # elsewhere in this repo. World-readable by default
  # (environment.etc is 0444 unless told otherwise), so currentCgi is a
  # plain `cat`, no permission dance needed.
  currentState = lib.listToAttrs (map
    (path: lib.nameValuePair (flagKey path) (lib.getAttrFromPath path f))
    flagPaths);

  stateJson = pkgs.writeText "dashboard-services-state.json" (builtins.toJSON currentState);

  # Bash `case` pattern accepting exactly the known flag keys, generated
  # once here — same idiom as traefik-dns01.nix's providerCaseArms.
  flagKeyCaseArms = lib.concatStringsSep "|" (map flagKey flagPaths);

  saveCgi = pkgs.writeShellApplication {
    name = "dashboard-services-save-cgi";
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

      # Reject anything that isn't exactly the known 15 boolean flags —
      # no extra keys, no missing keys, no non-boolean values. This is
      # the one gate standing between an arbitrary POST body and a real
      # nixos-rebuild, so it's deliberately strict rather than
      # best-effort.
      keys=$(printf '%s' "$body" | jq -r 'keys[]' 2>/dev/null) || fail "invalid JSON"
      while IFS= read -r k; do
        [ -z "$k" ] && continue
        case "$k" in
          ${flagKeyCaseArms}) ;;
          *) fail "unknown flag: $k" ;;
        esac
      done <<< "$keys"

      request_json="{}"
      ${lib.concatMapStringsSep "\n" (path: ''
        v=$(printf '%s' "$body" | jq -r '."${flagKey path}"' 2>/dev/null || true)
        case "$v" in
          true|false) ;;
          *) fail "missing or invalid flag: ${flagKey path}" ;;
        esac
        request_json=$(printf '%s' "$request_json" | jq --argjson v "$v" '."${flagKey path}" = $v')
      '') flagPaths}

      # Group-consistency normalization: a parent group toggled off
      # forces every one of its sub-flags to false, regardless of what
      # the client submitted — modules/authelia.nix hard-asserts
      # sso.authelia.enable requires sso.enable, and hitting that
      # assertion mid-rebuild (after the user already clicked Save) is a
      # much worse failure mode than never constructing an invalid
      # combination here. The frontend already does this same
      # normalization before submitting; this is the server-side
      # backstop, since saveCgi can't trust the client alone.
      sso_enable=$(printf '%s' "$request_json" | jq -r '."sso.enable"')
      if [ "$sso_enable" = "false" ]; then
        request_json=$(printf '%s' "$request_json" | jq '."sso.authelia.enable" = false')
      fi
      ha_enable=$(printf '%s' "$request_json" | jq -r '."homeAssistant.enable"')
      if [ "$ha_enable" = "false" ]; then
        request_json=$(printf '%s' "$request_json" | jq '."homeAssistant.zwave.enable" = false | ."homeAssistant.hacs.enable" = false')
      fi
      ma_enable=$(printf '%s' "$request_json" | jq -r '."mediaAcquisition.enable"')
      if [ "$ma_enable" = "false" ]; then
        request_json=$(printf '%s' "$request_json" | jq '."mediaAcquisition.seerr.enable" = false | ."mediaAcquisition.radarr.enable" = false | ."mediaAcquisition.sonarr.enable" = false | ."mediaAcquisition.jackett.enable" = false | ."mediaAcquisition.qbittorrent.enable" = false')
      fi

      mkdir -p ${runDir}
      printf '%s' "$request_json" > ${pendingFile}.tmp
      mv ${pendingFile}.tmp ${pendingFile}
      touch ${triggerFile}
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n{"ok":true}\n'
    '';
  };

  writeProgressFn = ''
    write_progress() {
      local state="$1" message="$2" now log_json
      now=$(date -Is)
      log_json="[]"
      [ -f ${progressFile} ] && log_json=$(jq -c '.log // []' ${progressFile} 2>/dev/null || echo '[]')
      jq -n --arg state "$state" --arg message "$message" --arg time "$now" --argjson log "$log_json" \
        '{state:$state, message:$message, log: ($log + [{time:$time, message:$message}])}' \
        > ${progressFile}.tmp
      mv ${progressFile}.tmp ${progressFile}
    }
  '';

  # Privileged oneshot, triggered by the path unit below — same
  # "unprivileged writer (saveCgi), privileged watcher" shape
  # modules/self-update.nix and modules/traefik-dns01.nix already
  # establish. Deliberately duplicates self-update.nix's fetch/extract
  # shape rather than sharing code with it (see the plan's Design
  # decision 2) — touching that separate, already-working, deployed
  # module to extract shared plumbing carries more risk than the ~20
  # duplicated lines here.
  applyScript = pkgs.writeShellApplication {
    name = "dashboard-services-apply";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.gnutar pkgs.gzip pkgs.coreutils pkgs.nixos-rebuild ];
    text = ''
      rm -f ${triggerFile}

      # Both features ultimately call nixos-rebuild switch, which cannot
      # safely run twice at once — refuse to start if self-update's own
      # apply is in flight rather than racing it. self-update.nix carries
      # the matching check against our own applyingFile in the other
      # direction.
      if [ -f ${selfUpdateApplyingFile} ]; then
        echo "error: a system update is currently in progress — try again in a moment" > ${runDir}/result
        exit 0
      fi

      if [ ! -f ${pendingFile} ]; then
        exit 0
      fi

      rm -f ${progressFile} ${buildLogFile} ${runDir}/result
      touch ${applyingFile}
      trap 'rm -f ${applyingFile}' EXIT
      ${writeProgressFn}

      # Pinned to the currently-installed release, not "latest" — a
      # service toggle should never silently also pull in an unrelated
      # version bump (confirmed with the user). Falls back to fetching
      # the latest tagged release if /persist/nixos-version doesn't
      # exist yet: that file is only ever written after a successful
      # self-update run (modules/self-update.nix), so any box that's
      # never been through one — every fresh install, and any
      # already-deployed box that hasn't self-updated since first boot —
      # has no such record. Whichever tag this run resolves gets written
      # back to that same file on success, so the very first use of
      # either feature on an old box self-heals the gap going forward.
      write_progress "running" "Determining current release..."
      if [ -f ${versionFile} ]; then
        tag=$(cat ${versionFile})
      else
        tag=$(curl -fsSL ${apiLatest} | jq -r .tag_name)
      fi
      if [ -z "$tag" ] || [ "$tag" = "null" ]; then
        write_progress "failed" "Could not determine which release to rebuild from"
        exit 1
      fi

      write_progress "running" "Downloading $tag..."
      rm -rf ${stagingDir}
      mkdir -p ${stagingDir}
      if ! curl -fsSL "https://github.com/${repo}/archive/refs/tags/$tag.tar.gz" -o ${stagingDir}/src.tar.gz; then
        write_progress "failed" "Download failed for $tag"
        exit 1
      fi
      tar xzf ${stagingDir}/src.tar.gz -C ${stagingDir}
      rm -f ${stagingDir}/src.tar.gz

      src_dir=$(find ${stagingDir} -mindepth 1 -maxdepth 1 -type d | head -n1)
      if [ -z "$src_dir" ]; then
        write_progress "failed" "Downloaded archive had no source directory"
        exit 1
      fi

      if [ ! -f ${secretsEnv} ]; then
        write_progress "failed" "${secretsEnv} is missing — see docs/DEPLOYMENT.md"
        exit 1
      fi

      # Full-file overwrite, every known flag — not just the ones that
      # changed (Design decision 4). Harmless: an unchanged flag forced
      # to its current value evaluates identically to leaving it alone.
      write_progress "running" "Writing service overrides..."
      {
        echo "{ lib, ... }:"
        echo "{"
        echo "  config = {"
        ${lib.concatMapStringsSep "\n" (path: ''
          v=$(jq -r '."${flagKey path}"' ${pendingFile})
          echo "    mySystem.features.${lib.concatStringsSep "." path} = lib.mkForce $v;"
        '') flagPaths}
        echo "  };"
        echo "}"
      } > ${overridesFile}.tmp
      mv ${overridesFile}.tmp ${overridesFile}

      write_progress "running" "Rebuilding (this can take a while)..."
      set -a
      # shellcheck disable=SC1091
      source ${secretsEnv}
      set +a
      : > ${buildLogFile}
      chmod 644 ${buildLogFile}
      if nixos-rebuild switch --flake "$src_dir#${hostName}" --impure 2>&1 | tee -a ${buildLogFile}; then
        echo "$tag" > ${versionFile}
        rm -rf ${stagingDir}
        rm -f ${pendingFile}
        write_progress "success" "Services updated"
      else
        write_progress "failed" "nixos-rebuild failed — see the log below"
        exit 1
      fi
    '';
  };

  statusCgi = pkgs.writeShellApplication {
    name = "dashboard-services-status-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.findutils ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      if [ -f ${runDir}/result ]; then
        jq -n --arg msg "$(cat ${runDir}/result)" '{state:"failed", message:$msg, log:[]}' 2>/dev/null \
          || echo '{"state":"failed","message":"error","log":[]}'
        exit 0
      fi
      if [ -f ${progressFile} ] && { [ -f ${applyingFile} ] || [ -n "$(find ${progressFile} -mmin -2 2>/dev/null)" ]; }; then
        build_log=""
        [ -f ${buildLogFile} ] && build_log=$(tail -n 500 ${buildLogFile})
        jq --arg buildLog "$build_log" '. + {buildLog: $buildLog}' ${progressFile}
      elif [ -f ${triggerFile} ] || [ -f ${pendingFile} ]; then
        echo '{"state":"running","message":"Starting...","log":[]}'
      else
        echo '{"state":"idle","message":"","log":[]}'
      fi
    '';
  };

  currentCgi = pkgs.writeShellApplication {
    name = "dashboard-services-current-cgi";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      cat ${stateJson}
    '';
  };
in
{
  options.mySystem.features.dashboardServices.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Dashboard-driven service enable/disable toggles — see
      modules/dashboard-services.nix and the "Services" accordion on the
      System Preferences page. Saving triggers a real nixos-rebuild
      switch pinned to the currently-installed release, via a
      /persist-backed overrides file (mySystem.features.dashboardServices
      itself is not one of the 15 toggleable flags).
    '';
  };

  config = lib.mkIf cfg.enable {
    users.users.dashboard-services = { isSystemUser = true; group = "dashboard-services"; };
    users.groups.dashboard-services = { };

    environment.etc."dashboard-services-state.json".source = stateJson;

    systemd.tmpfiles.rules = [
      "d ${runDir} 0750 dashboard-services dashboard-services - -"
    ];

    # Never wantedBy anything — purely triggered by the path unit below.
    systemd.services.dashboard-services-apply = {
      description = "Apply a dashboard-submitted service enable/disable change";
      # This service's own job is to run `nixos-rebuild switch` — which
      # means its own unit definition is, by construction, part of the
      # closure that switch is switching *to*, and will always look
      # "changed" relative to the generation that's currently running it.
      # Confirmed the hard way (twice): the journal showed "stopping the
      # following units: dashboard-services-apply.service,
      # fcgiwrap-dashboard-services.socket, fcgiwrap-traefik-dns01.socket,
      # traefik.service, ..." immediately followed by "Main process
      # exited, code=killed, status=15/TERM" — switch-to-configuration
      # killing nixos-rebuild switch before it could restart anything
      # past that point, leaving every unit in that stop list down until
      # the next externally-triggered switch. stopIfChanged alone does
      # NOT prevent this — it only controls *how* a restart happens
      # (stop-then-start vs. a single `systemctl restart`), not whether
      # one happens at all; that's what caused the first attempt at this
      # fix to still get killed. restartIfChanged=false plus
      # X-StopOnRemoval=false is the actual mechanism, and is exactly
      # nixpkgs' own solution to this same problem for its built-in
      # system.autoUpgrade.enable service — see
      # nixos/modules/tasks/auto-upgrade.nix's own nixos-upgrade.service,
      # which runs nixos-rebuild switch from inside itself the same way.
      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe applyScript;
      };
    };
    systemd.paths.dashboard-services-apply = {
      description = "Watch for a web-triggered service toggle change";
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathExists = triggerFile;
    };

    services.fcgiwrap.instances.dashboard-services = {
      process = {
        user = "dashboard-services";
        group = "dashboard-services";
      };
      socket = {
        user = config.services.nginx.user;
        group = config.services.nginx.group;
      };
    };

    # Rides on the existing dashboard vhost, same shape as
    # modules/self-update.nix and modules/traefik-dns01.nix. Admin-only
    # throughout: a failed apply's error message could hint at internal
    # state, and toggling whole services is a more consequential action
    # than any other preferences form on this vhost.
    services.nginx.virtualHosts.dashboard.locations = {
      "= /preferences/services/current" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-services.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe currentCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/services/save" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-services.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe saveCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param CONTENT_TYPE $content_type;
          fastcgi_param CONTENT_LENGTH $content_length;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/services/status" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-services.sock;
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
