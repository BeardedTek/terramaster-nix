{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.dashboardNetwork;
  lanIf = config.mySystem.lanInterface;

  loginEnabled = config.mySystem.features.sso.enable;

  overridesFile = "/persist/nixos-network-overrides.nix";
  # Snapshot of whatever overridesFile held immediately before the
  # currently-in-flight change — restored verbatim if nobody confirms
  # reachability within the confirm window (see applyScript below).
  backupFile = "/persist/nixos-network-overrides.nix.backup";

  runDir = "/run/dashboard-network";
  triggerFile = "${runDir}/trigger";
  pendingFile = "${runDir}/pending.json";
  pendingConfirmFile = "${runDir}/pending-confirm";
  confirmedFile = "${runDir}/confirmed";

  # modules/traefik.nix's own plain-HTTP, DNS/TLS-independent path to
  # this dashboard — exactly the address the confirm-reachability link
  # needs, read from its actual configured value rather than
  # hardcoding the port a second time.
  lanLocalPort = lib.removePrefix ":" config.services.traefik.staticConfigOptions.entryPoints.lan-local.address;

  # Shared with modules/dashboard-services.nix and modules/self-update.nix
  # — see modules/system-rebuild.nix's own comment for why. Its request
  # contract ({mode, label, kind}) needed zero changes to support a
  # third caller.
  sharedRunDir = "/run/system-rebuild";
  sharedRequestFile = "${sharedRunDir}/request.json";
  sharedTriggerFile = "${sharedRunDir}/trigger";
  sharedProgressFile = "${sharedRunDir}/progress.json";
  sharedBuildLogFile = "${sharedRunDir}/build.log";
  sharedApplyingFile = "${sharedRunDir}/applying";

  # Build-time snapshot of the currently-configured static addressing
  # (if any) — same "one file computes, another consumes" shape
  # dashboard-services.nix's own state JSON already uses. Doesn't (can't)
  # capture a DHCP-assigned address, since that's only known at runtime
  # — currentCgi below supplements this with a live `ip` read for that.
  ipv4Addrs = config.networking.interfaces.${lanIf}.ipv4.addresses or [ ];
  configuredState = {
    mode = if ipv4Addrs != [ ] then "static" else "dhcp";
    ip = if ipv4Addrs != [ ] then (builtins.head ipv4Addrs).address else null;
    prefix = if ipv4Addrs != [ ] then (builtins.head ipv4Addrs).prefixLength else null;
    gateway =
      let gw = config.networking.defaultGateway or null; in
      if gw == null then null
      else if builtins.isString gw then gw
      else gw.address or null;
    dns = config.networking.nameservers or [ ];
  };
  configuredStateJson = pkgs.writeText "dashboard-network-state.json" (builtins.toJSON configuredState);

  # Shared by saveCgi (validating a submitted mask/prefix) and applyScript
  # (re-validating pendingFile before trusting it — same "unprivileged
  # writer, privileged watcher never re-trusts blindly" posture the
  # traefik-dns01 saveCgi/applyScript split already uses, even though
  # here it's the same trust boundary saveCgi already enforced; cheap
  # insurance against pendingFile ever being hand-edited or corrupted).
  # Accepts either a bare CIDR integer (0-32) or a dotted subnet mask
  # (matching the form's own long-standing "255.255.255.0" placeholder)
  # — a dotted mask is converted by summing each octet's set-bit count
  # from a fixed lookup table of the only 9 values a valid octet can
  # take, rejecting anything else (including non-contiguous masks, since
  # a non-255 octet followed by a nonzero octet is rejected outright).
  netValidationFns = ''
    valid_octet() {
      case "$1" in
        ""|*[!0-9]*) return 1 ;;
      esac
      [ "$1" -le 255 ] || return 1
      case "$1" in
        0) ;;
        *) case "$1" in 0*) return 1 ;; esac ;;
      esac
      return 0
    }

    valid_ipv4() {
      local ip="$1" o1 o2 o3 o4
      IFS=. read -r o1 o2 o3 o4 <<< "$ip" || return 1
      [ -n "''${o4:-}" ] || return 1
      case "$ip" in *.*.*.*.*) return 1 ;; esac
      valid_octet "$o1" && valid_octet "$o2" && valid_octet "$o3" && valid_octet "$o4"
    }

    mask_octet_bits() {
      case "$1" in
        255) echo 8 ;; 254) echo 7 ;; 252) echo 6 ;; 248) echo 5 ;;
        240) echo 4 ;; 224) echo 3 ;; 192) echo 2 ;; 128) echo 1 ;; 0) echo 0 ;;
        *) return 1 ;;
      esac
    }

    # Prints the resolved prefix length (0-32) on stdout and returns 0,
    # or returns 1 with nothing printed.
    resolve_prefix() {
      local val="$1"
      case "$val" in
        ""|*[!0-9]*) ;;
        *) if [ "$val" -le 32 ]; then echo "$val"; return 0; fi ;;
      esac
      local o1 o2 o3 o4 b1 b2 b3 b4 seen_partial=0
      IFS=. read -r o1 o2 o3 o4 <<< "$val" || return 1
      [ -n "''${o4:-}" ] || return 1
      b1=$(mask_octet_bits "$o1") || return 1
      b2=$(mask_octet_bits "$o2") || return 1
      b3=$(mask_octet_bits "$o3") || return 1
      b4=$(mask_octet_bits "$o4") || return 1
      for b in "$b1" "$b2" "$b3" "$b4"; do
        if [ "$seen_partial" -eq 1 ] && [ "$b" -ne 0 ]; then return 1; fi
        [ "$b" -lt 8 ] && seen_partial=1
      done
      echo $(( b1 + b2 + b3 + b4 ))
      return 0
    }
  '';

  # Shared by applyScript's normal apply path and its own backup step
  # (when no overrides file exists yet, "no static config" is written
  # out as this exact DHCP content, so the backup is always valid,
  # directly-restorable overrides content regardless of what state the
  # box started in).
  writeDhcpOverridesFn = ''
    write_dhcp_overrides() {
      local dest="$1"
      {
        echo "{ lib, ... }:"
        echo "{"
        echo "  config = {"
        echo "    networking.interfaces.\"${lanIf}\".ipv4.addresses = lib.mkForce [ ];"
        echo "    networking.defaultGateway = lib.mkForce null;"
        echo "    networking.nameservers = lib.mkForce [ ];"
        echo "  };"
        echo "}"
      } > "$dest"
    }
  '';

  saveCgi = pkgs.writeShellApplication {
    name = "dashboard-network-save-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils ];
    text = ''
      ${netValidationFns}

      body=""
      if [ -n "''${CONTENT_LENGTH:-}" ] && [ "$CONTENT_LENGTH" -gt 0 ]; then
        body=$(head -c "$CONTENT_LENGTH")
      fi

      fail() {
        printf 'Status: 400 Bad Request\r\nContent-Type: application/json\r\n\r\n{"error":"%s"}\n' "$1"
        exit 0
      }

      # A change is still waiting on its own 5-minute confirm-or-rollback
      # window (see applyScript) — refuse a second one rather than let
      # its pending.json sit there forever unpicked-up (dashboard-network
      # -apply.service is a oneshot; a redundant trigger while it's
      # already active is silently swallowed, not queued).
      if [ -f ${pendingConfirmFile} ]; then
        fail "a network change is still pending confirmation — confirm or wait for it to resolve before making another change"
      fi

      mode=$(printf '%s' "$body" | jq -r '.mode // empty' 2>/dev/null || true)
      case "$mode" in
        dhcp)
          request_json='{"mode":"dhcp"}'
          ;;
        static)
          ip_val=$(printf '%s' "$body" | jq -r '.ip // empty' 2>/dev/null || true)
          prefix_val=$(printf '%s' "$body" | jq -r '.prefix // empty' 2>/dev/null || true)
          gateway_val=$(printf '%s' "$body" | jq -r '.gateway // empty' 2>/dev/null || true)

          valid_ipv4 "$ip_val" || fail "invalid IP address"
          valid_ipv4 "$gateway_val" || fail "invalid gateway"
          prefix=$(resolve_prefix "$prefix_val") || fail "invalid subnet mask / prefix"

          dns_json=$(printf '%s' "$body" | jq -c '.dns // []' 2>/dev/null || echo '[]')
          dns_count=$(printf '%s' "$dns_json" | jq 'length')
          [ "$dns_count" -ge 1 ] || fail "at least one DNS server is required"
          for i in $(seq 0 $((dns_count - 1))); do
            d=$(printf '%s' "$dns_json" | jq -r ".[$i]")
            valid_ipv4 "$d" || fail "invalid DNS server: $d"
          done

          request_json=$(jq -n --arg ip "$ip_val" --argjson prefix "$prefix" --arg gateway "$gateway_val" --argjson dns "$dns_json" \
            '{mode:"static", ip:$ip, prefix:$prefix, gateway:$gateway, dns:$dns}')
          ;;
        *)
          fail "mode must be \"dhcp\" or \"static\""
          ;;
      esac

      mkdir -p ${runDir}
      printf '%s' "$request_json" > ${pendingFile}.tmp
      mv ${pendingFile}.tmp ${pendingFile}
      touch ${triggerFile}
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n{"ok":true}\n'
    '';
  };

  # Privileged pre-step — same reasoning as dashboard-services.nix's own
  # applyScript for why writing /persist/nixos-network-overrides.nix
  # needs root while the actual rebuild is handed off to
  # modules/system-rebuild.nix. Unlike that module's script, though,
  # this one now stays running *through* the whole confirm-or-rollback
  # window (below) rather than exiting right after handoff — see the
  # restartIfChanged/X-StopOnRemoval note on its systemd service for
  # why that requires the same self-kill protection
  # modules/system-rebuild.nix's own apply service already needed.
  applyScript = pkgs.writeShellApplication {
    name = "dashboard-network-apply";
    runtimeInputs = [ pkgs.jq pkgs.coreutils ];
    text = ''
      ${netValidationFns}
      ${writeDhcpOverridesFn}

      rm -f ${triggerFile}

      if [ ! -f ${pendingFile} ]; then
        exit 0
      fi

      if [ -f ${sharedApplyingFile} ]; then
        exit 0
      fi

      # Snapshot whatever's live right now, before touching anything —
      # this is what gets restored if the change about to be applied
      # is never confirmed. No overrides file existing yet is itself
      # equivalent to DHCP (this module's own default posture), so the
      # backup is always valid, directly-restorable content either way.
      if [ -f ${overridesFile} ]; then
        cp ${overridesFile} ${backupFile}
      else
        write_dhcp_overrides ${backupFile}
      fi

      mode=$(jq -r '.mode' ${pendingFile})
      case "$mode" in
        dhcp)
          write_dhcp_overrides ${overridesFile}.tmp
          ;;
        static)
          ip_val=$(jq -r '.ip' ${pendingFile})
          prefix_val=$(jq -r '.prefix' ${pendingFile})
          gateway_val=$(jq -r '.gateway' ${pendingFile})
          valid_ipv4 "$ip_val" || exit 0
          valid_ipv4 "$gateway_val" || exit 0
          case "$prefix_val" in ""|*[!0-9]*) exit 0 ;; esac
          [ "$prefix_val" -le 32 ] || exit 0
          {
            echo "{ lib, ... }:"
            echo "{"
            echo "  config = {"
            echo "    networking.interfaces.\"${lanIf}\".ipv4.addresses = lib.mkForce [ { address = \"$ip_val\"; prefixLength = $prefix_val; } ];"
            echo "    networking.defaultGateway = lib.mkForce \"$gateway_val\";"
            printf '    networking.nameservers = lib.mkForce [ '
            jq -r '.dns[]' ${pendingFile} | while IFS= read -r d; do
              valid_ipv4 "$d" || continue
              printf '"%s" ' "$d"
            done
            echo '];'
            echo "  };"
            echo "}"
          } > ${overridesFile}.tmp
          ;;
        *)
          rm -f ${backupFile}
          exit 0
          ;;
      esac
      mv ${overridesFile}.tmp ${overridesFile}
      rm -f ${pendingFile}

      printf '%s' '{"mode":"current","label":"Network updated","kind":"network"}' > ${sharedRequestFile}.tmp
      mv ${sharedRequestFile}.tmp ${sharedRequestFile}
      touch ${sharedTriggerFile}

      # Wait for the rebuild this just triggered to actually finish —
      # bounded at 10 minutes as a safety ceiling in case something
      # hangs, well beyond how long any rebuild observed this session
      # has ever taken. Polls the exact same file/shape statusCgi
      # itself reads.
      final_state=""
      elapsed=0
      while [ "$elapsed" -lt 600 ]; do
        if [ -f ${sharedProgressFile} ] && [ ! -f ${sharedApplyingFile} ]; then
          k=$(jq -r '.kind // empty' ${sharedProgressFile} 2>/dev/null || true)
          s=$(jq -r '.state // empty' ${sharedProgressFile} 2>/dev/null || true)
          if [ "$k" = "network" ] && { [ "$s" = "success" ] || [ "$s" = "failed" ]; }; then
            final_state="$s"
            break
          fi
        fi
        sleep 2
        elapsed=$((elapsed + 2))
      done

      if [ "$final_state" != "success" ]; then
        # Failed, or timed out waiting — either way nothing was
        # successfully switched to, so there's nothing to roll back.
        rm -f ${backupFile}
        exit 0
      fi

      # Applied successfully — wait up to 5 minutes for confirmation
      # (dashboard-network-confirm-cgi touches confirmedFile) before
      # automatically reverting.
      rm -f ${confirmedFile}
      touch ${pendingConfirmFile}
      waited=0
      confirmed=0
      while [ "$waited" -lt 300 ]; do
        if [ -f ${confirmedFile} ]; then
          confirmed=1
          break
        fi
        sleep 5
        waited=$((waited + 5))
      done
      rm -f ${pendingConfirmFile} ${confirmedFile}

      if [ "$confirmed" -eq 1 ]; then
        rm -f ${backupFile}
        exit 0
      fi

      # Not confirmed in time — restore the pre-change config and fire
      # a fresh shared-runner request for it. Deliberately not waiting
      # on *this* one: the frontend's existing progress polling picks
      # up this new kind:"network" run the same way it would any other,
      # so there's nothing left for this script to do but hand off and
      # exit.
      if [ -f ${backupFile} ]; then
        cp ${backupFile} ${overridesFile}
        rm -f ${backupFile}
        printf '%s' '{"mode":"current","label":"Network change rolled back automatically (not confirmed within 5 minutes)","kind":"network"}' > ${sharedRequestFile}.tmp
        mv ${sharedRequestFile}.tmp ${sharedRequestFile}
        touch ${sharedTriggerFile}
      fi
    '';
  };

  confirmCgi = pkgs.writeShellApplication {
    name = "dashboard-network-confirm-cgi";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      mkdir -p ${runDir}
      touch ${confirmedFile}
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n{"ok":true}\n'
    '';
  };

  statusCgi = pkgs.writeShellApplication {
    name = "dashboard-network-status-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.findutils ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      # Gated on kind:"network" specifically — same reasoning as
      # dashboard-services.nix/self-update.nix's own status CGIs: a
      # sibling flow's progress, still inside its own settled-state
      # window, must never bleed into this one.
      progress_kind=""
      if [ -f ${sharedProgressFile} ] && { [ -f ${sharedApplyingFile} ] || [ -n "$(find ${sharedProgressFile} -mmin -2 2>/dev/null)" ]; }; then
        progress_kind=$(jq -r '.kind // empty' ${sharedProgressFile} 2>/dev/null || true)
      fi
      if [ "$progress_kind" = "network" ]; then
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

  # Reports the build-time-configured state plus a live read of what's
  # actually active right now — the latter is the only way to show a
  # real IP/gateway while in DHCP mode, since a DHCP lease isn't known
  # at Nix eval time. Read-only `ip` queries need no special privilege.
  currentCgi = pkgs.writeShellApplication {
    name = "dashboard-network-current-cgi";
    runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.iproute2 ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      # `|| true` on each: under set -e/pipefail (writeShellApplication's
      # default), `ip` failing on a not-yet-up or nonexistent interface
      # would otherwise kill the whole script right after the 200 OK
      # header was already sent — same "200 status, empty body, no
      # error anywhere" shape this repo has hit more than once this
      # session (see modules/traefik-dns01.nix's env_get comment).
      live_ip=$( (ip -4 -o addr show dev ${lanIf} 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1) || true)
      live_gateway=$( (ip route show default dev ${lanIf} 2>/dev/null | awk '{print $3}' | head -n1) || true)
      jq --arg liveIp "''${live_ip:-}" --arg liveGateway "''${live_gateway:-}" --arg lanLocalPort "${lanLocalPort}" \
        '. + {liveIp: $liveIp, liveGateway: $liveGateway, lanLocalPort: $lanLocalPort}' ${configuredStateJson}
    '';
  };
in
{
  options.mySystem.features.dashboardNetwork.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Dashboard-driven DHCP/Static IP configuration for
      mySystem.lanInterface — see modules/dashboard-network.nix and the
      "Network" accordion on the System Preferences page. Saving
      triggers a real nixos-rebuild switch (via
      modules/system-rebuild.nix's shared runner), via a
      /persist-backed overrides file. Hostname/Domain are not part of
      this — see the accordion's own copy for why.
    '';
  };

  config = lib.mkIf cfg.enable {
    users.users.dashboard-network = {
      isSystemUser = true;
      group = "dashboard-network";
      # Lets statusCgi (running as this user) traverse into
      # modules/system-rebuild.nix's shared run directory — same
      # reasoning as dashboard-services.nix's own extraGroups.
      extraGroups = [ "system-rebuild" ];
    };
    users.groups.dashboard-network = { };

    systemd.tmpfiles.rules = [
      "d ${runDir} 0750 dashboard-network dashboard-network - -"
    ];

    # Never wantedBy anything — purely triggered by the path unit below.
    systemd.services.dashboard-network-apply = {
      description = "Write network overrides, hand off to the shared rebuild runner, and wait through the confirm-or-rollback window";
      # This script now stays running through the rebuild it triggers
      # (to time the confirm window afterward), so — same reasoning as
      # modules/system-rebuild.nix's own apply service — it needs
      # protecting from switch-to-configuration killing it mid-wait,
      # since its own unit definition is part of the very closure that
      # rebuild switches to and will always look "changed."
      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe applyScript;
      };
    };
    systemd.paths.dashboard-network-apply = {
      description = "Watch for a web-triggered network config change";
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathExists = triggerFile;
    };

    services.fcgiwrap.instances.dashboard-network = {
      process = {
        user = "dashboard-network";
        group = "dashboard-network";
      };
      socket = {
        user = config.services.nginx.user;
        group = config.services.nginx.group;
      };
    };

    # Rides on the existing dashboard vhost, same shape as
    # modules/dashboard-services.nix. Admin-only throughout — changing
    # network addressing is at least as consequential as toggling
    # services.
    services.nginx.virtualHosts.dashboard.locations = {
      "= /preferences/network/current" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-network.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe currentCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/network/save" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-network.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe saveCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param CONTENT_TYPE $content_type;
          fastcgi_param CONTENT_LENGTH $content_length;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/network/status" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-network.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe statusCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/network/confirm" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-dashboard-network.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe confirmCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
    };
  };
}
