{ config, lib, pkgs, ... }:

let
  f = config.mySystem.features;
  hostName = config.networking.hostName;

  repo = "BeardedTek/terramaster-nix";
  apiLatest = "https://api.github.com/repos/${repo}/releases/latest";

  versionFile = "/persist/nixos-version";
  secretsEnv = "/persist/secrets/initial-passwords.env";
  stagingDir = "/persist/nixos-system-rebuild-staging";

  runDir = "/run/system-rebuild";
  requestFile = "${runDir}/request.json";
  triggerFile = "${runDir}/trigger";
  progressFile = "${runDir}/progress.json";
  buildLogFile = "${runDir}/build.log";
  applyingFile = "${runDir}/applying";

  # Shared by both self-update.nix and dashboard-services.nix — the one
  # place that fetches a release tag, extracts it, and runs
  # `nixos-rebuild switch`. Both those modules used to each carry their
  # own independent copy of this; that duplication produced three real
  # bugs unique to the newer copy (dashboard-services.nix) before this
  # was pulled out: the apply service killing itself mid-rebuild (its
  # own unit definition is always part of the closure being switched
  # to, so it always looks "changed" — restartIfChanged=false plus
  # unitConfig.X-StopOnRemoval=false, matching nixpkgs' own
  # nixos-upgrade.service, is the actual fix; stopIfChanged=false alone
  # does *not* work, it only controls how a restart happens, not
  # whether one happens), and a missing `jq` in a status CGI's
  # runtimeInputs. Fixing this once, here, means neither caller needs
  # to get any of that right again.
  # References $kind from the enclosing script, not a parameter — every
  # call site in applyScript runs after $kind is set from the request,
  # so this stays simple rather than threading a third argument through
  # every call. Lets each caller's own statusCgi tell "my flow is
  # active" apart from "the other flow just finished" — before this,
  # both statusCgis showed whichever flow's progress file was most
  # recently written/still within its 2-minute settled-state window,
  # regardless of which one the viewer actually triggered, which reads
  # as "it's re-running" when it's really just the other feature's
  # recent result bleeding through a shared file.
  writeProgressFn = ''
    write_progress() {
      local state="$1" message="$2" now log_json
      now=$(date -Is)
      log_json="[]"
      [ -f ${progressFile} ] && log_json=$(jq -c '.log // []' ${progressFile} 2>/dev/null || echo '[]')
      jq -n --arg state "$state" --arg message "$message" --arg time "$now" --argjson log "$log_json" --arg kind "$kind" \
        '{state:$state, message:$message, kind:$kind, log: ($log + [{time:$time, message:$message}])}' \
        > ${progressFile}.tmp
      mv ${progressFile}.tmp ${progressFile}
    }
  '';

  # Triggered by either self-update.nix's triggerCgi (writing directly,
  # via the system-rebuild group) or dashboard-services.nix's own small
  # privileged pre-step (writing as root, after it's written
  # /persist/nixos-service-overrides.nix from its own pending request).
  # Runs as root — no sudo, no password, systemd-triggered the same way
  # every other apply script in this repo is.
  applyScript = pkgs.writeShellApplication {
    name = "system-rebuild-apply";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.gnutar pkgs.gzip pkgs.coreutils pkgs.nixos-rebuild ];
    text = ''
      rm -f ${triggerFile}

      if [ ! -f ${requestFile} ]; then
        exit 0
      fi

      # umask 022 (not the shell default of usually 022 anyway, but
      # made explicit rather than assumed): progressFile/buildLogFile
      # need to be world-readable so *either* caller's own unprivileged
      # statusCgi (running as a different system user each) can read
      # them back — neither file holds anything secret, so this is
      # simpler and more robust than a group-ownership dance for files
      # two different unprivileged users both need to read.
      umask 022

      rm -f ${progressFile} ${buildLogFile}
      touch ${applyingFile}
      trap 'rm -f ${applyingFile}' EXIT
      ${writeProgressFn}

      mode=$(jq -r '.mode' ${requestFile})
      label=$(jq -r '.label' ${requestFile})
      kind=$(jq -r '.kind' ${requestFile})
      rm -f ${requestFile}

      # mode:"current" reads /persist/nixos-version (falling back to
      # the latest tagged release if that file doesn't exist yet — any
      # box that's never been through one successful rebuild via
      # *either* caller has no such file). mode:"latest" always fetches
      # the newest tagged release.
      write_progress "running" "Determining release to build..."
      if [ "$mode" = "current" ] && [ -f ${versionFile} ]; then
        tag=$(cat ${versionFile})
      else
        tag=$(curl -fsSL ${apiLatest} | jq -r .tag_name)
      fi
      if [ -z "$tag" ] || [ "$tag" = "null" ]; then
        write_progress "failed" "Could not determine which release to rebuild from"
        exit 1
      fi
      # A caller that doesn't know the resolved tag ahead of time (e.g.
      # self-update.nix's triggerCgi, requesting mode:"latest") can
      # embed the literal placeholder %TAG% in its label; substituted
      # here once the real tag is known. `%` isn't a glob metacharacter,
      # so this is a plain literal substring replacement.
      label=''${label//%TAG%/$tag}

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

      # "Rebuilding (this can take a while)..." is matched verbatim by
      # dashboard/content/preferences.md's Update-modal STEPS regex
      # (the "download" step's own completion trigger) — keep this
      # exact phrase if it's ever edited.
      write_progress "running" "Rebuilding (this can take a while)..."
      set -a
      # shellcheck disable=SC1091
      source ${secretsEnv}
      set +a
      : > ${buildLogFile}
      if nixos-rebuild switch --flake "$src_dir#${hostName}" --impure 2>&1 | tee -a ${buildLogFile}; then
        echo "$tag" > ${versionFile}
        rm -rf ${stagingDir}
        write_progress "success" "$label"
      else
        write_progress "failed" "nixos-rebuild failed — see the log below"
        exit 1
      fi
    '';
  };
in
{
  config = lib.mkIf (f.selfUpdate.enable || f.dashboardServices.enable) {
    users.groups.system-rebuild = { };

    systemd.tmpfiles.rules = [
      # 0770 root:system-rebuild — root (dashboard-services' own
      # privileged pre-step) and any system-rebuild group member
      # (self-update.nix's triggerCgi, running as the unprivileged
      # nas-update user, added to this group) can write a request here
      # directly. progress.json/build.log are separately made
      # world-readable via applyScript's own umask, not via this rule.
      "d ${runDir} 0770 root system-rebuild - -"
    ];

    # Never wantedBy anything — purely triggered by the path unit
    # below. restartIfChanged/X-StopOnRemoval: see the long comment on
    # applyScript above for why this is the one unit in this repo that
    # actually needs both.
    systemd.services.system-rebuild-apply = {
      description = "Fetch a release and run nixos-rebuild switch, on behalf of self-update or dashboard-services";
      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe applyScript;
      };
    };
    systemd.paths.system-rebuild-apply = {
      description = "Watch for a rebuild request from self-update or dashboard-services";
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathExists = triggerFile;
    };
  };
}
