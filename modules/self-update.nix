{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.selfUpdate;
  hostName = config.networking.hostName;

  repo = "BeardedTek/terramaster-nix";
  apiLatest = "https://api.github.com/repos/${repo}/releases/latest";

  versionFile = "/persist/nixos-version";
  secretsEnv = "/persist/secrets/initial-passwords.env";
  stagingDir = "/persist/nixos-update-staging";
  triggerFile = "/run/nas-update/trigger-update";
  applyingFile = "/run/nas-update/applying";
  statusFile = "/var/lib/dashboard/update-status.json";
  progressFile = "/var/lib/dashboard/update-progress.json";

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
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.gnutar pkgs.coreutils pkgs.nixos-rebuild ];
    text = ''
      rm -f ${triggerFile}
      touch ${applyingFile}
      trap 'rm -f ${applyingFile}' EXIT

      ${writeStatusFn}

      write_progress() {
        jq -n --arg state "$1" --arg message "$2" '{state:$state, message:$message}' > ${progressFile}.tmp
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
      if nixos-rebuild switch --flake "$src_dir#${hostName}" --impure; then
        echo "$latest" > ${versionFile}
        rm -rf ${stagingDir}
        write_progress "success" "Updated to $latest"
        write_status
      else
        write_progress "failed" "nixos-rebuild failed — see: journalctl -u nas-update-apply"
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

  # While applyingFile exists, serves the live progressFile; once the
  # apply finishes (applyingFile removed via the trap above), always
  # falls back to statusFile — which nas-update-apply's own last step
  # already refreshed, so there's no stale-progress state to fall into.
  statusCgi = pkgs.writeShellApplication {
    name = "nas-update-status-cgi";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      if [ -f ${applyingFile} ] && [ -f ${progressFile} ]; then
        cat ${progressFile}
      elif [ -f ${statusFile} ]; then
        cat ${statusFile}
      else
        printf '{"current":"unknown","latest":null,"updateAvailable":false}'
      fi
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    users.users.nas-update = { isSystemUser = true; group = "nas-update"; };
    users.groups.nas-update = { };

    systemd.tmpfiles.rules = [
      "d /run/nas-update 0750 nas-update nas-update - -"
      # auth_basic_user_file is read directly by the nginx *worker*
      # process (config.services.nginx.user/.group, not root) — unlike
      # EnvironmentFile= secrets elsewhere in this repo (read by systemd
      # itself, as root, before dropping privileges), so root:root 0600
      # actually breaks this one instead of being the safe default.
      # `z` fixes ownership/mode on every activation regardless of how
      # the file was actually delivered, and is a no-op if it's not
      # there yet (first boot, before the secret's been copied in).
      "z /etc/nas-update/htpasswd 0640 root ${config.services.nginx.group} - -"
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
    # port 8097) — no new Traefik backend, no new firewall port. Both
    # locations sit behind the same password; status alone is low-risk
    # (just "is a newer version out"), but there's no reason to split
    # the auth boundary for it.
    services.nginx.virtualHosts.dashboard.locations = {
      "= /update/status" = {
        extraConfig = ''
          auth_basic "NAS Update";
          auth_basic_user_file /etc/nas-update/htpasswd;
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
          auth_basic "NAS Update";
          auth_basic_user_file /etc/nas-update/htpasswd;
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
