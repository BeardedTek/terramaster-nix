{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.dashboardServices;
  f = config.mySystem.features;

  loginEnabled = config.mySystem.features.sso.enable;

  overridesFile = "/persist/nixos-service-overrides.nix";

  runDir = "/run/dashboard-services";
  triggerFile = "${runDir}/trigger";
  pendingFile = "${runDir}/pending.json";

  # The actual fetch/extract/nixos-rebuild-switch/progress-tracking work
  # is shared with modules/self-update.nix via modules/system-rebuild.nix
  # — see that file's own comment for why (this module used to carry an
  # independent copy of all of that, which is what originally hit the
  # apply-service-kills-itself and missing-jq bugs; only the shared copy
  # needs to get that right now).
  sharedRunDir = "/run/system-rebuild";
  sharedRequestFile = "${sharedRunDir}/request.json";
  sharedTriggerFile = "${sharedRunDir}/trigger";
  sharedProgressFile = "${sharedRunDir}/progress.json";
  sharedBuildLogFile = "${sharedRunDir}/build.log";
  sharedApplyingFile = "${sharedRunDir}/applying";

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

  # Privileged oneshot, triggered by the path unit below — same
  # "unprivileged writer (saveCgi), privileged watcher" shape
  # modules/self-update.nix and modules/traefik-dns01.nix already
  # establish. Short-lived: the only thing it does that genuinely needs
  # root is writing /persist/nixos-service-overrides.nix (the
  # unprivileged dashboard-services user can't write to /persist); the
  # actual fetch/rebuild is handed off to modules/system-rebuild.nix's
  # shared runner. Never itself runs nixos-rebuild, so — unlike that
  # shared runner — it isn't exposed to the "own unit definition always
  # looks changed" self-kill problem and doesn't need
  # restartIfChanged/X-StopOnRemoval.
  applyScript = pkgs.writeShellApplication {
    name = "dashboard-services-apply";
    runtimeInputs = [ pkgs.jq pkgs.coreutils ];
    text = ''
      rm -f ${triggerFile}

      if [ ! -f ${pendingFile} ]; then
        exit 0
      fi

      # Both this and self-update.nix ultimately hand off to the same
      # shared rebuild runner, which can't safely run twice at once —
      # leave pendingFile in place if it's already busy; the next
      # successful save naturally picks it back up (this apply script
      # itself carries no state across runs, so there's nothing here to
      # roll back).
      if [ -f ${sharedApplyingFile} ]; then
        exit 0
      fi

      # Full-file overwrite, every known flag — not just the ones that
      # changed (Design decision 4 from the original plan). Harmless:
      # an unchanged flag forced to its current value evaluates
      # identically to leaving it alone.
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
      rm -f ${pendingFile}

      printf '%s' '{"mode":"current","label":"Services updated"}' > ${sharedRequestFile}.tmp
      mv ${sharedRequestFile}.tmp ${sharedRequestFile}
      touch ${sharedTriggerFile}
    '';
  };

  # While the shared runner is active (or finished within the last
  # couple of minutes), serves its live progress. Otherwise falls back
  # to "running" for the brief window between saveCgi's own trigger and
  # the shared runner actually picking it up, or "idle".
  statusCgi = pkgs.writeShellApplication {
    name = "dashboard-services-status-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.findutils ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      if [ -f ${sharedProgressFile} ] && { [ -f ${sharedApplyingFile} ] || [ -n "$(find ${sharedProgressFile} -mmin -2 2>/dev/null)" ]; }; then
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
      switch (via modules/system-rebuild.nix's shared runner) pinned to
      the currently-installed release, via a /persist-backed overrides
      file (mySystem.features.dashboardServices itself is not one of
      the 15 toggleable flags).
    '';
  };

  config = lib.mkIf cfg.enable {
    users.users.dashboard-services = {
      isSystemUser = true;
      group = "dashboard-services";
      # Lets statusCgi (running as this user) traverse into
      # modules/system-rebuild.nix's shared run directory (0770
      # root:system-rebuild) to read its progress file and check its
      # applying lock. progress.json/build.log are separately made
      # world-readable by the shared runner's own umask, but that's
      # moot without traversal into the directory in the first place.
      extraGroups = [ "system-rebuild" ];
    };
    users.groups.dashboard-services = { };

    environment.etc."dashboard-services-state.json".source = stateJson;

    systemd.tmpfiles.rules = [
      "d ${runDir} 0750 dashboard-services dashboard-services - -"
    ];

    # Never wantedBy anything — purely triggered by the path unit below.
    systemd.services.dashboard-services-apply = {
      description = "Write service overrides and hand off to the shared rebuild runner";
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
