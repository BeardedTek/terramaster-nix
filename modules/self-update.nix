{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.selfUpdate;

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

  # The actual fetch/extract/nixos-rebuild-switch/progress-tracking work
  # is shared with modules/dashboard-svcconfig.nix via
  # modules/system-rebuild.nix — see that file's own comment for why
  # (this module used to carry an independent copy of all of that,
  # which is what originally hit the apply-service-kills-itself and
  # missing-jq bugs; only the shared copy needs to get that right now).
  sharedRunDir = "/run/system-rebuild";
  sharedRequestFile = "${sharedRunDir}/request.json";
  sharedTriggerFile = "${sharedRunDir}/trigger";
  sharedProgressFile = "${sharedRunDir}/progress.json";
  sharedBuildLogFile = "${sharedRunDir}/build.log";
  sharedApplyingFile = "${sharedRunDir}/applying";

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

  # Shared between checkScript and statusCgi's own fallback path, so
  # both ever write the exact same {current, latest, updateAvailable,
  # releaseUrl} shape into statusFile — the frontend only has to
  # understand one settled-state format, regardless of which of the two
  # wrote it last.
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
  # a rebuild (from either this feature or dashboard-svcconfig's) is in
  # flight, so it can't clobber statusFile with a stale "no update
  # available" read mid-rebuild — the shared runner refreshes
  # statusFile-equivalent state itself via the progress file, so
  # nothing is lost by skipping here.
  checkScript = pkgs.writeShellApplication {
    name = "nas-update-check";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.coreutils ];
    text = ''
      [ -f ${sharedApplyingFile} ] && exit 0
      ${writeStatusFn}
      write_status
    '';
  };

  # Just writes a request for the shared rebuild runner
  # (modules/system-rebuild.nix) and returns — runs as the unprivileged
  # nas-update user (see below), not root. Needs write access to
  # ${sharedRunDir}, granted via the system-rebuild group (see
  # extraGroups below) since the actual privileged work happens
  # entirely in system-rebuild-apply.service now.
  triggerCgi = pkgs.writeShellApplication {
    name = "nas-update-trigger-cgi";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      if [ -f ${sharedApplyingFile} ]; then
        printf 'Status: 409 Conflict\r\nContent-Type: text/plain\r\n\r\nA rebuild is already in progress — try again in a moment.\n'
        exit 0
      fi
      # %TAG% is a placeholder the shared runner substitutes with the
      # actual resolved tag once it knows it — this caller requests
      # mode:"latest" and doesn't find out which tag that is until the
      # shared runner does. kind:"update" lets statusCgi below tell "my
      # own run" apart from a dashboard-svcconfig run that happens to
      # still be within its own settled-state window.
      printf '%s' '{"mode":"latest","label":"Updated to %TAG%","kind":"update"}' > ${sharedRequestFile}.tmp
      mv ${sharedRequestFile}.tmp ${sharedRequestFile}
      touch ${sharedTriggerFile}
      printf 'Status: 200 OK\r\nContent-Type: text/plain\r\n\r\nUpdate triggered\n'
    '';
  };

  # While a rebuild is active (or finished within the last couple of
  # minutes), serves the shared runner's live progress. Otherwise runs
  # a fresh GitHub check on every single request rather than trusting
  # nas-update-check's hourly cache — confirmed the hard way, the
  # "Check for updates" button read straight from that cache and kept
  # reporting the previous release as latest for up to an hour after a
  # new one actually went out. A live check here is one fast HTTP GET,
  # well within GitHub's unauthenticated rate limit for something only
  # a human clicks occasionally — the hourly timer still runs too,
  # mainly so statusFile has *something* in it before anyone's ever
  # opened the page.
  statusCgi = pkgs.writeShellApplication {
    name = "nas-update-status-cgi";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.coreutils pkgs.findutils ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      # Not just "is applyingFile still there" — a run that fails fast
      # can finish and clean up applyingFile before the frontend's
      # first poll ever lands, silently discarding the failure message.
      # Also treat a progress file written in the last 2 minutes as
      # current, so a fast-finished run's result is still visible for a
      # bit rather than only during the run itself. Gated on
      # kind:"update" specifically — otherwise a dashboard-svcconfig run
      # still inside its own settled-state window would show up here
      # too, reading as "it's updating again" when nothing update-related
      # actually re-triggered.
      if [ -f ${sharedProgressFile} ] && { [ -f ${sharedApplyingFile} ] || [ -n "$(find ${sharedProgressFile} -mmin -2 2>/dev/null)" ]; }; then
        progress_kind=$(jq -r '.kind // empty' ${sharedProgressFile} 2>/dev/null || true)
        if [ "$progress_kind" = "update" ]; then
          build_log=""
          [ -f ${sharedBuildLogFile} ] && build_log=$(tail -n 500 ${sharedBuildLogFile})
          jq --arg buildLog "$build_log" '. + {buildLog: $buildLog}' ${sharedProgressFile}
          exit 0
        fi
      fi
      ${writeStatusFn}
      write_status
      cat ${statusFile}
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    users.users.nas-update = {
      isSystemUser = true;
      group = "nas-update";
      # Lets triggerCgi write directly into modules/system-rebuild.nix's
      # shared run directory (0770 root:system-rebuild) without needing
      # its own privileged relay step — unlike dashboard-svcconfig.nix's
      # own pre-step, this feature has no root-only work to do before
      # handing off (no overrides file to write), so there's nothing
      # else a privileged step would be for.
      extraGroups = [ "system-rebuild" ];
    };
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
