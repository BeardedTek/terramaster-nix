{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.traefikDns01;
  hostName = config.networking.hostName;
  domain = config.mySystem.domain;

  # Same posture as modules/self-update.nix: /update/trigger's admin gate
  # only exists when SSO/dashboard login is enabled at all — off entirely
  # otherwise, matching every other dashboard location's behavior.
  loginEnabled = config.mySystem.features.sso.enable;

  runDir = "/run/traefik-dns01";
  triggerFile = "${runDir}/trigger";
  pendingFile = "${runDir}/pending.json";
  resultFile = "${runDir}/result";
  envFile = "/etc/traefik/traefik.env";
  gceKeyFile = "/etc/traefik/gce-service-account.json";

  defaultDomain = "custom.${hostName}.${domain}";
  defaultWildcard = "*.custom.${hostName}.${domain}";

  # One entry per dashboard-selectable provider: the exact env var names
  # modules/traefik.nix's envsubst-templated dnsChallenge.provider expects
  # lego itself to read from the process environment once TRAEFIK_DNS_PROVIDER
  # selects that provider. Names taken from Traefik/Lego's own DNS-01
  # provider docs (https://doc.traefik.io/traefik/https/acme/#providers) —
  # double-check against a live doc pull before shipping if any of these
  # turn out stale by the time this is implemented.
  #
  # gcloud is the one special case: the admin pastes a whole service-account
  # JSON blob rather than a single token, so its "field" is the JSON body
  # itself (written to gceKeyFile by applyScript below, not embedded
  # directly into traefik.env as a single line) rather than a plain env var.
  providerFields = {
    linode = [ "LINODE_TOKEN" ];
    cloudflare = [ "CF_DNS_API_TOKEN" ];
    digitalocean = [ "DO_AUTH_TOKEN" ];
    route53 = [ "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" ];
    duckdns = [ "DUCKDNS_TOKEN" ];
    godaddy = [ "GODADDY_API_KEY" "GODADDY_API_SECRET" ];
    namecheap = [ "NAMECHEAP_API_USER" "NAMECHEAP_API_KEY" ];
    gcloud = [ "GCE_PROJECT" ];
    azure = [ "AZURE_CLIENT_ID" "AZURE_CLIENT_SECRET" "AZURE_SUBSCRIPTION_ID" "AZURE_TENANT_ID" "AZURE_RESOURCE_GROUP" ];
    ovh = [ "OVH_ENDPOINT" "OVH_APPLICATION_KEY" "OVH_APPLICATION_SECRET" "OVH_CONSUMER_KEY" ];
    porkbun = [ "PORKBUN_API_KEY" "PORKBUN_SECRET_API_KEY" ];
    vultr = [ "VULTR_API_KEY" ];
    hetzner = [ "HETZNER_API_KEY" ];
    gandi = [ "GANDI_BEARER_TOKEN" ];
    desec = [ "DESEC_TOKEN" ];
  };

  # Bash `case` arms accepting exactly the provider ids above — generated
  # once here rather than hand-duplicated in both saveCgi and applyScript.
  providerCaseArms = lib.concatStringsSep "|" (builtins.attrNames providerFields);

  # Every request writes a *complete* replacement traefik.env — never
  # appends — so switching providers can't leave a previous provider's
  # credentials lingering in the file. Shared between saveCgi (which
  # validates before ever touching pendingFile) and applyScript (which
  # trusts pendingFile completely, since only saveCgi — running as the
  # dedicated unprivileged traefik-dns01 user, never directly reachable
  # except through this same validation) ever writes it.
  writeEnvFn = ''
    write_env_line() {
      # Reject embedded newlines — the one way a single field's value
      # could inject an extra, attacker-chosen KEY=VALUE line into
      # traefik.env (systemd's EnvironmentFile= parses it line-by-line;
      # this file is the *only* thing that feeds Traefik's process
      # environment, so this is the one place that actually matters).
      case "$2" in
        *$'\n'*) echo "refusing to write $1: contains a newline" >&2; exit 1 ;;
      esac
      printf '%s=%s\n' "$1" "$2"
    }
  '';

  # Reads a single KEY's current value out of traefik.env, used both by
  # saveCgi (blank field submitted = keep whatever's already set, for the
  # *same* provider only — see below) and currentCgi (reporting which
  # fields are already configured, without ever exposing their values).
  # Deliberately a line-by-line `read`, not `source`ing the file directly
  # — the whole reason write_env_line above rejects embedded newlines is
  # to keep this file inert as *data*; sourcing it would trust that
  # invariant instead of just reading it.
  readEnvFn = ''
    env_get() {
      local key="$1" found=""
      # "Key not present" is an expected, normal outcome here (every
      # value this reads is optional-by-nature — a legacy/hand-written
      # traefik.env may only have some of them, and a not-yet-configured
      # box may have none) — never let it read as script failure. Without
      # the explicit "|| true" and "return 0", a `while read` loop that
      # runs to EOF without matching returns the *last read's* own
      # failure status (1, from hitting end-of-file) as the whole
      # function's exit status; under `set -e` (every writeShellApplication
      # here uses it) that silently killed the entire CGI right after its
      # 200 OK header had already gone out — confirmed the hard way: every
      # symptom (200 status, completely empty body, and nothing in either
      # fcgiwrap's or nginx's logs, since nothing here ever printed an
      # error or even reached nginx's own error paths) matched exactly.
      if [ -f ${envFile} ]; then
        while IFS='=' read -r k v; do
          if [ "$k" = "$key" ]; then
            found="$v"
            break
          fi
        done < ${envFile} || true
      fi
      printf '%s' "$found"
      return 0
    }
  '';

  saveCgi = pkgs.writeShellApplication {
    name = "traefik-dns01-save-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils ];
    text = ''
      ${readEnvFn}
      current_provider=$(env_get TRAEFIK_DNS_PROVIDER)

      body=""
      if [ -n "''${CONTENT_LENGTH:-}" ] && [ "$CONTENT_LENGTH" -gt 0 ]; then
        body=$(head -c "$CONTENT_LENGTH")
      fi

      fail() {
        printf 'Status: 400 Bad Request\r\nContent-Type: application/json\r\n\r\n{"error":"%s"}\n' "$1"
        exit 0
      }

      provider=$(printf '%s' "$body" | jq -r '.provider // empty' 2>/dev/null || true)
      case "$provider" in
        ${providerCaseArms}) ;;
        *) fail "unknown provider" ;;
      esac

      domain_val=$(printf '%s' "$body" | jq -r '.domain // empty' 2>/dev/null || true)
      wildcard_val=$(printf '%s' "$body" | jq -r '.wildcard // empty' 2>/dev/null || true)
      [ -n "$domain_val" ] && [ -n "$wildcard_val" ] || fail "domain and wildcard are required"
      # Plain DNS-label characters only — same spirit as dashboard-login's
      # username guard (modules/dashboard-login.nix), just a wider
      # character set (dots/hyphens/asterisk are legal in a hostname or
      # wildcard pattern, commas/quotes/newlines/etc. are not and have no
      # business appearing in a domain here).
      case "$domain_val" in
        *[!a-zA-Z0-9.-]*) fail "invalid domain" ;;
      esac
      case "$wildcard_val" in
        *[!a-zA-Z0-9.*-]*) fail "invalid wildcard" ;;
      esac

      mkdir -p ${runDir}
      request_json=$(jq -n --arg provider "$provider" --arg domain "$domain_val" --arg wildcard "$wildcard_val" \
        '{provider: $provider, domain: $domain, wildcard: $wildcard, fields: {}}')

      # Every field this provider needs must end up present and
      # single-line; gcloud's lone "field" is the pasted service-account
      # JSON itself, which is legitimately multi-line, so it skips the
      # newline check every other provider's fields get. A field
      # submitted blank falls back to whatever's already saved for it —
      # but only when re-saving the *same* provider that's already
      # configured; switching providers has no "existing value" to fall
      # back to for a field that belongs to the new provider only, so a
      # blank field there is still a hard failure.
      ${lib.concatMapStringsSep "\n" (provider: ''
        if [ "$provider" = "${provider}" ]; then
          ${lib.concatMapStringsSep "\n" (field: ''
            val=$(printf '%s' "$body" | jq -r '.fields."${field}" // empty' 2>/dev/null || true)
            if [ -z "$val" ] && [ "$provider" = "$current_provider" ]; then
              val=$(env_get "${field}")
            fi
            [ -n "$val" ] || fail "missing field: ${field}"
            ${lib.optionalString (provider != "gcloud") ''
              case "$val" in *$'\n'*) fail "invalid field: ${field}" ;; esac
            ''}
            request_json=$(printf '%s' "$request_json" | jq --arg v "$val" '.fields."${field}" = $v')
          '') providerFields.${provider}}
        fi
      '') (builtins.attrNames providerFields)}

      if [ "$provider" = "gcloud" ]; then
        gce_json=$(printf '%s' "$body" | jq -r '.fields."GCE_SERVICE_ACCOUNT_JSON" // empty' 2>/dev/null || true)
        if [ -z "$gce_json" ] && [ "$provider" = "$current_provider" ] && [ -f ${gceKeyFile} ]; then
          gce_json=$(cat ${gceKeyFile})
        fi
        [ -n "$gce_json" ] || fail "missing field: GCE_SERVICE_ACCOUNT_JSON"
        printf '%s' "$gce_json" | jq . >/dev/null 2>&1 || fail "GCE_SERVICE_ACCOUNT_JSON is not valid JSON"
        request_json=$(printf '%s' "$request_json" | jq --arg v "$gce_json" '.fields."GCE_SERVICE_ACCOUNT_JSON" = $v')
      fi

      printf '%s' "$request_json" > ${pendingFile}.tmp
      mv ${pendingFile}.tmp ${pendingFile}
      rm -f ${resultFile}
      touch ${triggerFile}
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n{"ok":true}\n'
    '';
  };

  applyScript = pkgs.writeShellApplication {
    name = "traefik-dns01-apply";
    runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.systemd ];
    text = ''
      rm -f ${triggerFile}
      ${writeEnvFn}

      if [ ! -f ${pendingFile} ]; then
        echo "error: no pending request" > ${resultFile}
        exit 0
      fi

      provider=$(jq -r '.provider' ${pendingFile})
      domain_val=$(jq -r '.domain' ${pendingFile})
      wildcard_val=$(jq -r '.wildcard' ${pendingFile})

      {
        write_env_line TRAEFIK_DNS_PROVIDER "$provider"
        write_env_line TRAEFIK_EXTRA_DOMAIN "$domain_val"
        write_env_line TRAEFIK_EXTRA_WILDCARD "$wildcard_val"

        if [ "$provider" = "gcloud" ]; then
          jq -r '.fields."GCE_PROJECT"' ${pendingFile} | { read -r v; write_env_line GCE_PROJECT "$v"; }
          jq -r '.fields."GCE_SERVICE_ACCOUNT_JSON"' ${pendingFile} > ${gceKeyFile}.tmp
          mv ${gceKeyFile}.tmp ${gceKeyFile}
          chown root:traefik-dns01 ${gceKeyFile}
          chmod 640 ${gceKeyFile}
          write_env_line GCE_SERVICE_ACCOUNT_FILE "${gceKeyFile}"
        else
          for field in $(jq -r '.fields | keys[]' ${pendingFile}); do
            value=$(jq -r --arg f "$field" '.fields[$f]' ${pendingFile})
            write_env_line "$field" "$value"
          done
        fi
      } > ${envFile}.tmp
      mv ${envFile}.tmp ${envFile}
      # 640, not 600: saveCgi and currentCgi (both running unprivileged as
      # traefik-dns01 via fcgiwrap) need to read this back — for the
      # "blank field = keep existing value" fallback and the "which
      # fields are already configured" status report, respectively.
      # Traefik itself never needs to read this directly either way —
      # systemd's EnvironmentFile= loads it as root before dropping to
      # the traefik user, same as always.
      chown root:traefik-dns01 ${envFile}
      chmod 640 ${envFile}
      rm -f ${pendingFile}

      if systemctl restart traefik && systemctl is-active --quiet traefik; then
        echo "ok" > ${resultFile}
      else
        echo "error: traefik failed to restart — check journalctl -u traefik" > ${resultFile}
      fi
    '';
  };

  # Reports which provider/domain/wildcard are currently configured, and
  # which of that provider's credential fields already have a value set
  # — as booleans only, never the actual secret values. Lets the
  # dashboard form pre-select the right provider and pre-fill the
  # (non-secret) domain/wildcard on load, and show "already set — leave
  # blank to keep" placeholders for credentials instead of either leaving
  # them blank with no explanation or echoing real secrets back to the
  # browser on every page load.
  currentCgi = pkgs.writeShellApplication {
    name = "traefik-dns01-current-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      ${readEnvFn}

      provider=$(env_get TRAEFIK_DNS_PROVIDER)
      domain_val=$(env_get TRAEFIK_EXTRA_DOMAIN)
      wildcard_val=$(env_get TRAEFIK_EXTRA_WILDCARD)

      fields_json="{}"
      # Checks every field name across every provider — traefik.env only
      # ever holds one provider's fields at a time (applyScript always
      # does a full rewrite, never appends), so this naturally reports
      # nothing for whichever provider isn't currently active, without
      # needing to special-case "only check the current provider's own
      # fields" here.
      ${lib.concatMapStringsSep "\n" (field: ''
        if [ -n "$(env_get ${field})" ]; then
          fields_json=$(printf '%s' "$fields_json" | jq --arg k "${field}" '. + {($k): true}')
        fi
      '') (lib.unique (lib.concatLists (builtins.attrValues providerFields)))}
      if [ -n "$(env_get GCE_SERVICE_ACCOUNT_FILE)" ]; then
        fields_json=$(printf '%s' "$fields_json" | jq '. + {"GCE_SERVICE_ACCOUNT_JSON": true}')
      fi

      jq -n --arg provider "$provider" --arg domain "$domain_val" --arg wildcard "$wildcard_val" --argjson fields "$fields_json" \
        '{provider: $provider, domain: $domain, wildcard: $wildcard, fields: $fields}'
    '';
  };

  statusCgi = pkgs.writeShellApplication {
    name = "traefik-dns01-status-cgi";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils ];
    text = ''
      printf 'Status: 200 OK\r\nContent-Type: text/plain\r\n\r\n'
      # Same "still fresh" window idiom as nas-update-status-cgi
      # (modules/self-update.nix) — this operation finishes in well under
      # a second, so 2 minutes is generous, not tight.
      if [ -f ${resultFile} ] && [ -n "$(find ${resultFile} -mmin -2 2>/dev/null)" ]; then
        cat ${resultFile}
      elif [ -f ${triggerFile} ] || [ -f ${pendingFile} ]; then
        echo "pending"
      else
        echo "idle"
      fi
    '';
  };

  defaultsScript = pkgs.writeShellApplication {
    name = "traefik-dns01-defaults";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      # Seeds a harmless, always-valid traefik.env before Traefik's very
      # first start, so an unconfigured box never renders an empty
      # Host(``) rule or empty ACME domain (see modules/traefik.nix's
      # customDomainRouter comment). Never touches an existing file —
      # once an admin has actually saved something via the dashboard,
      # this is a permanent no-op.
      if [ ! -f ${envFile} ]; then
        mkdir -p "$(dirname ${envFile})"
        {
          echo "TRAEFIK_DNS_PROVIDER=linode"
          echo "TRAEFIK_EXTRA_DOMAIN=${defaultDomain}"
          echo "TRAEFIK_EXTRA_WILDCARD=${defaultWildcard}"
        } > ${envFile}.tmp
        mv ${envFile}.tmp ${envFile}
        chown root:traefik-dns01 ${envFile}
        chmod 640 ${envFile}
      fi
    '';
  };
in
{
  options.mySystem.features.traefikDns01.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Dashboard-driven DNS-01 Let's Encrypt provider configuration — see
      modules/traefik-dns01.nix and the "Let's Encrypt" accordion on the
      System Preferences page. Defaults on: the seeded-defaults service
      alone is what keeps modules/traefik.nix's now-env-templated
      dnsChallenge.provider from rendering an empty/broken value on a box
      that's never touched this page.
    '';
  };

  config = lib.mkIf cfg.enable {
    users.users.traefik-dns01 = { isSystemUser = true; group = "traefik-dns01"; };
    users.groups.traefik-dns01 = { };

    systemd.tmpfiles.rules = [
      "d ${runDir} 0750 traefik-dns01 traefik-dns01 - -"
      # Fixes ownership/permissions on *every* boot, unlike
      # traefik-dns01-defaults.service's one-time "only if missing" seed
      # or applyScript's chown-on-save — neither of those touch a file
      # that already existed *before* this feature did. Confirmed the
      # hard way on young: a pre-existing, manually-provisioned
      # traefik.env (0600 root:root, predating this module entirely)
      # never got upgraded, so saveCgi/currentCgi (running unprivileged
      # as traefik-dns01 via fcgiwrap) couldn't read it back at all — the
      # exact same class of bug as modules/lldap.nix's own tmpfiles fix,
      # for the exact same reason. `z` is a no-op if the file isn't there
      # yet, same as everywhere else this pattern's used in this repo.
      "z ${envFile} 0640 root traefik-dns01 - -"
      "z ${gceKeyFile} 0640 root traefik-dns01 - -"
    ];

    systemd.services.traefik-dns01-defaults = {
      description = "Seed a safe default /etc/traefik/traefik.env if none exists yet";
      before = [ "traefik.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe defaultsScript;
      };
    };

    # Never wantedBy anything — purely triggered by the path unit below,
    # same "unprivileged writer, privileged watcher" shape
    # modules/self-update.nix's nas-update-apply already establishes.
    systemd.services.traefik-dns01-apply = {
      description = "Apply a dashboard-submitted DNS-01 provider change";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe applyScript;
      };
    };
    systemd.paths.traefik-dns01-apply = {
      description = "Watch for a web-triggered DNS-01 provider change";
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathExists = triggerFile;
    };

    services.fcgiwrap.instances.traefik-dns01 = {
      process = {
        user = "traefik-dns01";
        group = "traefik-dns01";
      };
      socket = {
        user = config.services.nginx.user;
        group = config.services.nginx.group;
      };
    };

    # Rides on the existing dashboard vhost (modules/dashboard.nix) — no
    # new Traefik backend, no new firewall port, same "one module adds
    # its own locations to the shared vhost" shape modules/self-update.nix
    # already uses on this exact vhost. Both admin-gated: unlike
    # self-update's status endpoint (readable by any logged-in user),
    # even *reading* DNS-01 status here is admin-only, since a failed
    # attempt's error message could hint at which fields were wrong.
    services.nginx.virtualHosts.dashboard.locations = {
      "= /preferences/dns-provider/save" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-traefik-dns01.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe saveCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param CONTENT_TYPE $content_type;
          fastcgi_param CONTENT_LENGTH $content_length;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/dns-provider/status" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-traefik-dns01.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe statusCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
      "= /preferences/dns-provider/current" = {
        extraConfig = ''
          ${lib.optionalString loginEnabled "auth_request /internal/dashboard-admin-check;"}
          fastcgi_pass unix:/run/fcgiwrap-traefik-dns01.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe currentCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
    };
  };
}
