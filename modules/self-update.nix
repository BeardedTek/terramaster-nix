{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.selfUpdate;
  hostName = config.networking.hostName;

  # /update/status and /update/trigger below now rely entirely on
  # modules/dashboard-login.nix's auth_request checks for protection —
  # there's no htpasswd fallback anymore (removed once dashboard login
  # itself could tell admins apart from ordinary users). That makes
  # enabling selfUpdate without also enabling sso leave /update/trigger
  # completely open, same as every other dashboard location when SSO's
  # off (see modules/dashboard.nix's loginEnabled) — consistent with the
  # rest of this vhost, but worth calling out since this module used to
  # be independently self-protecting.
  loginEnabled = config.mySystem.features.sso.enable;

  repo = "BeardedTek/terramaster-nix";
  apiLatest = "https://api.github.com/repos/${repo}/releases/latest";

  versionFile = "/persist/nixos-version";
  secretsEnv = "/persist/secrets/initial-passwords.env";
  stagingDir = "/persist/nixos-update-staging";
  triggerFile = "/run/nas-update/trigger-update";
  applyingFile = "/run/nas-update/applying";
  # Both this module and modules/dashboard-services.nix ultimately call
  # nixos-rebuild switch, which cannot safely run twice at once —
  # dashboard-services.nix carries the matching check against our own
  # applyingFile in the other direction.
  dashboardServicesApplyingFile = "/run/dashboard-services/applying";
  # Under /run/nas-update (tmpfs, owned by the unprivileged nas-update
  # user — see below), not /var/lib/dashboard: confirmed the hard way
  # that nas-update-status-cgi, invoked via fcgiwrap as that user, can't
  # write into /var/lib/dashboard at all (root:root 0755, from
  # dashboard-metrics' own StateDirectory — readable, not writable, by
  # anyone else). The write failed silently under this script's `set
  # -e` *after* the CGI had already sent its 200 OK headers, so the
  # client just got an empty body ("Unexpected end of JSON input") with
  # no indication anything had gone wrong server-side. Same "no
  # persistence across reboots, cheap to regenerate" posture
  # metrics.json already uses, just a level up in /run instead of
  # /var/lib.
  statusFile = "/run/nas-update/update-status.json";
  progressFile = "/run/nas-update/update-progress.json";
  buildLogFile = "/run/nas-update/build.log";

  # Shared between checkScript and the end of applyScript, so both ever
  # write the exact same {current, latest, updateAvailable, releaseUrl}
  # shape into statusFile — the frontend only has to understand one
  # settled-state format, regardless of which of the two wrote it last.
  writeStatusFn = ''
    write_status() {
      local current latest_json
      current="unknown"
      [ -f ${versionFile} ] && current=$(cat ${versionFile})

      if ! latest_json=$(curl -fsSL ${apiLatest}); then
        jq -n --arg current "$current" \
          '{current:$current, latest:null, updateAvailable:false, error:"could not reach GitHub"}' \
          > ${statusFile}.tmp
        mv ${statusFile}.tmp ${statusFile}
        return
      fi

      local latest url available
      latest=$(echo "$latest_json" | jq -r .tag_name)
      url=$(echo "$latest_json" | jq -r .html_url)
      available="false"
      [ "$current" != "$latest" ] && available="true"

      jq -n --arg current "$current" --arg latest "$latest" --argjson available "$available" --arg url "$url" \
        '{current:$current, latest:$latest, updateAvailable:$available, releaseUrl:$url}' \
        > ${statusFile}.tmp
      mv ${statusFile}.tmp ${statusFile}
    }
  '';

  # Periodic check only — never touches the system. Skips entirely while
  # an apply is in flight (applyingFile present) so it can't clobber
  # statusFile with a stale "no update available" read mid-rebuild —
  # nas-update-apply refreshes statusFile itself once it's done, so
  # nothing is lost by skipping here.
  checkScript = pkgs.writeShellApplication {
    name = "nas-update-check";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.coreutils ];
    text = ''
      [ -f ${applyingFile} ] && exit 0
      ${writeStatusFn}
      write_status
    '';
  };

  # The actual privileged work — fetch the latest tagged release's source
  # (GitHub's auto-generated archive/refs/tags/<tag>.tar.gz, not the ISO
  # release asset — much smaller, and it's exactly what
  # nixos-rebuild --flake needs), stage it on /persist (survives the
  # tmpfs root if the box reboots mid-download, deleted again on
  # success), and switch to it. Runs as root — no sudo, no password
  # prompt, since this is a systemd-triggered service, not an
  # interactive shell (see the trigger mechanism below for how it's
  # actually invoked without giving the trigger itself root).
  #
  # applyingFile brackets the whole run (trap removes it no matter how
  # the script exits) so nas-update-check knows to stay out of the way,
  # and statusCgi below knows whether to serve the live progressFile or
  # the settled statusFile.
  applyScript = pkgs.writeShellApplication {
    name = "nas-update-apply";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.gnutar pkgs.gzip pkgs.coreutils pkgs.nixos-rebuild ];
    text = ''
      rm -f ${triggerFile}

      if [ -f ${dashboardServicesApplyingFile} ]; then
        jq -n '{state:"failed", message:"A service change is currently being applied — try again in a moment.", log:[]}' \
          > ${progressFile}.tmp
        mv ${progressFile}.tmp ${progressFile}
        exit 0
      fi

      rm -f ${progressFile} ${buildLogFile}
      touch ${applyingFile}
      trap 'rm -f ${applyingFile}' EXIT

      ${writeStatusFn}

      # Appends to a running log (stage transitions, not the raw build
      # output — that's buildLogFile, tailed in separately by statusCgi)
      # instead of just overwriting the one current message, so the
      # frontend's log accordion can show the whole run's history, not
      # just whatever the last poll happened to catch.
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

      write_progress "running" "Checking latest release..."
      latest=$(curl -fsSL ${apiLatest} | jq -r .tag_name)
      if [ -z "$latest" ] || [ "$latest" = "null" ]; then
        write_progress "failed" "Could not determine the latest release from GitHub"
        write_status
        exit 1
      fi

      write_progress "running" "Downloading $latest..."
      rm -rf ${stagingDir}
      mkdir -p ${stagingDir}
      if ! curl -fsSL "https://github.com/${repo}/archive/refs/tags/$latest.tar.gz" -o ${stagingDir}/src.tar.gz; then
        write_progress "failed" "Download failed for $latest"
        write_status
        exit 1
      fi
      tar xzf ${stagingDir}/src.tar.gz -C ${stagingDir}
      rm -f ${stagingDir}/src.tar.gz

      src_dir=$(find ${stagingDir} -mindepth 1 -maxdepth 1 -type d | head -n1)
      if [ -z "$src_dir" ]; then
        write_progress "failed" "Downloaded archive had no source directory"
        write_status
        exit 1
      fi

      if [ ! -f ${secretsEnv} ]; then
        write_progress "failed" "${secretsEnv} is missing — see docs/DEPLOYMENT.md"
        write_status
        exit 1
      fi

      write_progress "running" "Rebuilding (this can take a while)..."
      set -a
      # shellcheck disable=SC1091
      source ${secretsEnv}
      set +a
      # Real nixos-rebuild output, not just our own stage messages —
      # captured to buildLogFile (world-readable, see below) so
      # statusCgi can tail it into the response while this is still
      # running, for the frontend's log accordion.
      : > ${buildLogFile}
      chmod 644 ${buildLogFile}
      if nixos-rebuild switch --flake "$src_dir#${hostName}" --impure 2>&1 | tee -a ${buildLogFile}; then
        echo "$latest" > ${versionFile}
        rm -rf ${stagingDir}
        write_progress "success" "Updated to $latest"
        write_status
      else
        write_progress "failed" "nixos-rebuild failed — see the log below"
        write_status
        exit 1
      fi
    '';
  };

  # Just sets a trigger file and returns — runs as the unprivileged
  # nas-update user (see below), not root. The actual privileged work
  # happens in nas-update-apply, started by the path unit below once it
  # sees this file — same "unprivileged writer, privileged watcher" shape
  # nixpkgs' own services.minio module uses for restart-on-credential-
  # change (systemd.paths.minio-root-credentials -> minio-restart.service).
  triggerCgi = pkgs.writeShellApplication {
    name = "nas-update-trigger-cgi";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      touch ${triggerFile}
      printf 'Status: 200 OK\r\nContent-Type: text/plain\r\n\r\nUpdate triggered\n'
    '';
  };

  # While applyingFile exists, serves the live progressFile. Otherwise
  # runs a fresh GitHub check on every single request rather than
  # trusting nas-update-check's hourly cache — confirmed the hard way,
  # the "Check for updates" button read straight from that cache and
  # kept reporting the previous release as latest for up to an hour
  # after a new one actually went out. A live check here is one fast
  # HTTP GET, well within GitHub's unauthenticated rate limit for
  # something only a human clicks occasionally — the hourly timer still
  # runs too, mainly so statusFile has *something* in it before anyone's
  # ever opened the page.
  statusCgi = pkgs.writeShellApplication {
    name = "nas-update-status-cgi";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.coreutils pkgs.findutils ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      # Not just "is applyingFile still there" — a run that fails fast
      # (confirmed the hard way: a bad PATH inside nas-update-apply made
      # it fail in under a second) can finish and clean up applyingFile
      # before the frontend's first poll ever lands, silently discarding
      # the failure message. Also treat a progressFile written in the
      # last 2 minutes as current, so a fast-finished run's result is
      # still visible for a bit rather than only during the run itself.
      if [ -f ${progressFile} ] && { [ -f ${applyingFile} ] || [ -n "$(find ${progressFile} -mmin -2 2>/dev/null)" ]; }; then
        build_log=""
        [ -f ${buildLogFile} ] && build_log=$(tail -n 500 ${buildLogFile})
        jq --arg buildLog "$build_log" '. + {buildLog: $buildLog}' ${progressFile}
        exit 0
      fi
      ${writeStatusFn}
      write_status
      cat ${statusFile}
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    users.users.nas-update = { isSystemUser = true; group = "nas-update"; };
    users.groups.nas-update = { };

    systemd.tmpfiles.rules = [
      "d /run/nas-update 0750 nas-update nas-update - -"
    ];

    systemd.services.nas-update-check = {
      description = "Check for a newer Bearded NAS release";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe checkScript;
      };
    };
    systemd.timers.nas-update-check = {
      description = "Run nas-update-check periodically";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "1h";
      };
    };

    # Never wantedBy anything — purely triggered by the path unit below.
    systemd.services.nas-update-apply = {
      description = "Apply the latest Bearded NAS release";
      # Same latent bug modules/dashboard-services.nix's own apply
      # service hit and fixed the hard way (twice — the first attempt,
      # stopIfChanged=false, does NOT prevent this: it only controls how
      # a restart happens, not whether one happens at all). This
      # service's own job is to run `nixos-rebuild switch`, so its own
      # unit definition is always part of the closure being switched to,
      # and looks "changed" relative to the generation currently running
      # it — switch-to-configuration would otherwise SIGTERM this unit
      # (itself, mid-run) partway through, killing nixos-rebuild switch
      # before it can restart whatever else it had queued to stop/start.
      # restartIfChanged=false plus X-StopOnRemoval=false is nixpkgs' own
      # solution to this exact problem for system.autoUpgrade.enable's
      # built-in nixos-upgrade.service (nixos/modules/tasks/auto-upgrade.nix),
      # which runs nixos-rebuild switch from inside itself the same way.
      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe applyScript;
      };
    };
    systemd.paths.nas-update-apply = {
      description = "Watch for a web-triggered update request";
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathExists = triggerFile;
    };

    services.fcgiwrap.instances.nas-update = {
      process = {
        user = "nas-update";
        group = "nas-update";
      };
      socket = {
        user = config.services.nginx.user;
        group = config.services.nginx.group;
      };
    };

    # Rides on the existing dashboard vhost (modules/dashboard.nix,
    # port 8097) — no new Traefik backend, no new firewall port.
    # /update/status is gated behind plain dashboard login (any logged-in
    # user, not admin-only) — same as /metrics.json in modules/dashboard.nix,
    # per the dashboard-wide login design. This used to predate that
    # design and was left unauthenticated; fixed here to actually match.
    # /update/trigger below needs admin specifically, not just login.
    services.nginx.virtualHosts.dashboard.locations = {
      "= /update/status" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-auth-check;"}
          fastcgi_pass unix:/run/fcgiwrap-nas-update.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe statusCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /update/trigger" = {
        extraConfig = ''
          # Gated on dashboard-login admin status specifically (not just
          # "logged in") — see modules/dashboard-login.nix's
          # adminCheckCgi/dashboard-admin-check. This used to be a
          # separate htpasswd prompt layered on top of dashboard login;
          # that's gone now that dashboard login itself distinguishes
          # admins from ordinary LDAP users, so there's no longer a
          # meaningful second secret to re-enter. Note this location
          # previously had NO auth_request at all despite a comment
          # claiming otherwise — the general "/" catch-all's auth_request
          # never actually covered this exact-match location, so
          # /update/trigger was protected by htpasswd alone. Fixed here,
          # not just carried forward, since removing htpasswd without
          # this would have left it wide open.
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-nas-update.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe triggerCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param CONTENT_TYPE $content_type;
          fastcgi_param CONTENT_LENGTH $content_length;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
    };
  };
}
