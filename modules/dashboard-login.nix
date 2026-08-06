{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.sso;
  domain = config.mySystem.domain;
  baseDn = lib.concatMapStringsSep "," (part: "dc=${part}") (lib.splitString "." domain);
  dashboardSite = config.mySystem.dashboardSite;

  sessionDir = "/run/dashboard-sessions";
  sessionTtlMinutes = "720"; # 12h — matches the tmpfiles age-cleanup rule below
  ldapBindPasswordFile = "/etc/dashboard-login/ldap_password";

  # Same pinned reconciliation script modules/lldap.nix / modules/authelia.nix
  # / modules/media-stack.nix (Jellyfin) all use — here for a dedicated
  # read-only LDAP account this module needs to check a *different* user's
  # group membership after they've authenticated (their own bind can only
  # ever see their own entry — confirmed the hard way with Authelia's
  # bind account earlier). See modules/lldap.nix for the full rationale.
  lldapBootstrapScript = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/lldap/lldap/48a0a8d961f32bd8e3263b202053ce49a6c94781/scripts/bootstrap.sh";
    sha256 = "1cf85qxdh5s5xk773i00wmv34cnd75nkl4x096jnyxbcp634wnmd";
  };
  ldapUserConfigs = pkgs.linkFarm "dashboard-login-ldap-bind-user-config" [
    {
      name = "dashboard-login.json";
      path = pkgs.writeText "dashboard-login.json" (builtins.toJSON {
        id = "dashboard-login";
        email = "dashboard-login@${domain}";
        password_file = ldapBindPasswordFile;
        groups = [ "lldap_strict_readonly" ];
      });
    }
  ];
  ldapProvisionScript = pkgs.writeShellApplication {
    name = "dashboard-login-provision-ldap-bind-user";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.jo pkgs.bash pkgs.coreutils ];
    text = ''
      export LLDAP_URL="http://127.0.0.1:17170"
      export LLDAP_ADMIN_USERNAME="admin"
      export LLDAP_ADMIN_PASSWORD_FILE="/etc/lldap/ldap_user_pass"
      export USER_CONFIGS_DIR="${ldapUserConfigs}"
      export LLDAP_SET_PASSWORD_PATH="${lib.getExe' pkgs.lldap "lldap_set_password"}"
      bash ${lldapBootstrapScript}
    '';
  };

  # Dedicated unprivileged user for both CGIs — same "unprivileged writer,
  # privileged watcher"-adjacent idiom modules/self-update.nix's nas-update
  # user already establishes, just here it's "unprivileged reader/writer
  # of its own session state," nothing privileged involved at all.
  loginCgi = pkgs.writeShellApplication {
    name = "dashboard-login-cgi";
    runtimeInputs = [ pkgs.openldap pkgs.jq pkgs.coreutils pkgs.openssl ];
    text = ''
      body=""
      if [ -n "''${CONTENT_LENGTH:-}" ] && [ "$CONTENT_LENGTH" -gt 0 ]; then
        body=$(head -c "$CONTENT_LENGTH")
      fi

      fail() {
        printf 'Status: 401 Unauthorized\r\nContent-Type: application/json\r\n\r\n{"error":"invalid credentials"}\n'
        exit 0
      }

      username=$(printf '%s' "$body" | jq -r '.username // empty' 2>/dev/null || true)
      password=$(printf '%s' "$body" | jq -r '.password // empty' 2>/dev/null || true)
      [ -n "$username" ] && [ -n "$password" ] || fail

      # Reject anything that isn't a plain LDAP uid — a crafted username
      # containing commas/equals/etc. could otherwise manipulate the bind
      # DN's structure (LDAP DN injection), same class of concern URL
      # path-traversal checks guard against elsewhere in this repo.
      case "$username" in
        *[!a-zA-Z0-9._-]*) fail ;;
      esac

      user_dn="uid=$username,ou=people,${baseDn}"

      ldapwhoami -x -H ldap://127.0.0.1:3890 -D "$user_dn" -w "$password" >/dev/null 2>&1 || fail

      # Admin status: the user's own bind can only ever see their own
      # entry (confirmed the hard way elsewhere in this repo), so this
      # has to be a *separate* search as the dedicated dashboard-login
      # service account, not the just-authenticated user's own bind.
      # A failure here (e.g. LDAP hiccup) fails safe to isAdmin=false
      # rather than blocking login entirely over a non-essential check.
      is_admin="false"
      bind_password=$(cat ${ldapBindPasswordFile} 2>/dev/null || echo "")
      if [ -n "$bind_password" ]; then
        if ldapsearch -x -H ldap://127.0.0.1:3890 \
          -D "uid=dashboard-login,ou=people,${baseDn}" -w "$bind_password" \
          -b "ou=groups,${baseDn}" \
          "(&(objectClass=groupOfNames)(cn=admins)(member=$user_dn))" dn \
          2>/dev/null | grep -q "^dn:"; then
          is_admin="true"
        fi
      fi

      token=$(openssl rand -hex 32)
      mkdir -p ${sessionDir}
      jq -n --arg username "$username" --argjson isAdmin "$is_admin" \
        '{username:$username, isAdmin:$isAdmin}' > "${sessionDir}/$token"
      chmod 600 "${sessionDir}/$token"
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\nSet-Cookie: dashboard_session=%s; Path=/; HttpOnly; SameSite=Lax\r\n\r\n{"ok":true}\n' "$token"
    '';
  };

  # Shared by both the internal auth_request check and the public
  # /whoami endpoint below — reads the session cookie and, if valid,
  # prints the session file's own contents to stdout. Callers decide what
  # to do with that (auth_request only cares about the exit code; whoami
  # relays the JSON straight through).
  readSessionSnippet = ''
    token=""
    if [ -n "''${HTTP_COOKIE:-}" ]; then
      token=$(printf '%s' "$HTTP_COOKIE" | tr ';' '\n' | sed -n 's/^[[:space:]]*dashboard_session=\(.*\)$/\1/p' | head -n1)
    fi

    # Tokens are openssl-rand-hex only — reject anything else outright
    # before it ever touches a filesystem path (this token becomes part
    # of a path below; a stray "../" here would otherwise be a real
    # path-traversal risk).
    valid_session=""
    if [ -n "$token" ]; then
      case "$token" in
        *[!a-zA-Z0-9]*) : ;;
        *)
          session_file="${sessionDir}/$token"
          valid_session=$(find "$session_file" -mmin -${sessionTtlMinutes} 2>/dev/null || true)
          ;;
      esac
    fi
  '';

  # Used via nginx's auth_request on every non-public location — see
  # modules/dashboard.nix. Deliberately not routed through Authelia at
  # all: its session cookie is scoped to domain: beardedtek.com, and
  # browsers never send a domain-scoped cookie to a raw IP request, so
  # that path would permanently look logged-out regardless of a
  # successful login elsewhere. A plain host-only cookie (no Domain=
  # attribute, set here) works correctly and independently on every
  # access path since it's scoped to whichever exact host/IP issued it.
  sessionCheckCgi = pkgs.writeShellApplication {
    name = "dashboard-session-check-cgi";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.gnused ];
    text = ''
      ${readSessionSnippet}
      if [ -n "$valid_session" ]; then
        printf 'Status: 200 OK\r\n\r\n'
      else
        printf 'Status: 401 Unauthorized\r\n\r\n'
      fi
    '';
  };

  # Public (unlike the internal auth-check above) — called directly by
  # dashboard/static/js/auth-nav.js on every page load to decide whether
  # to show a Login link or the profile menu, and whether that menu's
  # System Preferences item shows at all.
  whoamiCgi = pkgs.writeShellApplication {
    name = "dashboard-whoami-cgi";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.gnused pkgs.jq ];
    text = ''
      ${readSessionSnippet}
      printf 'Status: 200 OK\r\nContent-Type: application/json\r\n\r\n'
      if [ -n "$valid_session" ]; then
        jq -c '. + {authenticated:true}' "$session_file"
      else
        printf '{"authenticated":false}\n'
      fi
    '';
  };

  # Same as sessionCheckCgi above, but also requires the session's own
  # isAdmin flag (set at login time — see loginCgi's admins-group check).
  # Used via auth_request wherever a location needs more than just "any
  # logged-in user" — currently only /update/trigger (modules/self-update.nix),
  # since triggering a full system rebuild is a meaningfully bigger blast
  # radius than viewing Services/Samba/NFS.
  adminCheckCgi = pkgs.writeShellApplication {
    name = "dashboard-admin-check-cgi";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.gnused pkgs.jq ];
    text = ''
      ${readSessionSnippet}
      if [ -n "$valid_session" ] && [ "$(jq -r '.isAdmin // false' "$session_file" 2>/dev/null)" = "true" ]; then
        printf 'Status: 200 OK\r\n\r\n'
      else
        printf 'Status: 401 Unauthorized\r\n\r\n'
      fi
    '';
  };

  logoutCgi = pkgs.writeShellApplication {
    name = "dashboard-logout-cgi";
    runtimeInputs = [ pkgs.coreutils pkgs.gnused ];
    text = ''
      token=""
      if [ -n "''${HTTP_COOKIE:-}" ]; then
        token=$(printf '%s' "''${HTTP_COOKIE}" | tr ';' '\n' | sed -n 's/^[[:space:]]*dashboard_session=\(.*\)$/\1/p' | head -n1)
      fi
      case "$token" in
        "" | *[!a-zA-Z0-9]*) : ;;
        *) rm -f "${sessionDir}/$token" ;;
      esac
      printf 'Status: 302 Found\r\nSet-Cookie: dashboard_session=; Path=/; Max-Age=0\r\nLocation: /\r\n\r\n'
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    users.users.dashboard-login = { isSystemUser = true; group = "dashboard-login"; };
    users.groups.dashboard-login = { };

    systemd.tmpfiles.rules = [
      # 0700 dashboard-login-only — session tokens are bearer credentials,
      # nothing else on the box should be able to read them. Age field
      # (12h) auto-removes stale session files on its own, independent of
      # (but consistent with) sessionTtlMinutes' own explicit check above.
      "d ${sessionDir} 0700 dashboard-login dashboard-login 12h -"
      # loginCgi (fcgiwrap, User=dashboard-login) reads this delivered
      # secret directly — same pattern, same fix, as
      # modules/unix-ldap-login.nix's own bindPasswordFile `z` rule: a
      # plain `chmod 600` (root-only, e.g. from the installer wizard)
      # leaves it unreadable by that user, and the admin-group check
      # silently fails safe to isAdmin=false rather than failing loudly —
      # confirmed the hard way, a real admin account logged in fine but
      # never saw System Preferences.
      "z ${ldapBindPasswordFile} 0640 root dashboard-login - -"
    ];

    # Re-run on every activation, same reconciliation shape as
    # modules/lldap.nix's lldap-provision-users / modules/authelia.nix's
    # authelia-provision-ldap-bind-user.
    systemd.services.dashboard-login-provision-ldap-bind-user = {
      description = "Ensure the dashboard login's dedicated LDAP bind account exists in LLDAP";
      after = [ "lldap.service" "lldap-provision-users.service" ];
      requires = [ "lldap.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe ldapProvisionScript;
      };
    };

    services.fcgiwrap.instances.dashboard-login = {
      process = {
        user = "dashboard-login";
        group = "dashboard-login";
      };
      socket = {
        user = config.services.nginx.user;
        group = config.services.nginx.group;
      };
    };

    # Rides on the existing dashboard vhost (modules/dashboard.nix) — no
    # new Traefik backend, no new firewall port, same "one module adds
    # its own locations to the shared vhost" shape
    # modules/self-update.nix already uses on this exact vhost.
    services.nginx.virtualHosts.dashboard.locations = {
      # Internal-only — never reached directly by a client, only via
      # auth_request from modules/dashboard.nix's protected locations.
      # Cookie forwarding is explicit (not auto-included) to match this
      # vhost's existing CGI locations, none of which pull in nginx's
      # default fastcgi_params file either.
      "= /internal/dashboard-auth-check".extraConfig = ''
        internal;
        fastcgi_pass unix:/run/fcgiwrap-dashboard-login.sock;
        fastcgi_param SCRIPT_FILENAME ${lib.getExe sessionCheckCgi};
        fastcgi_param REQUEST_METHOD $request_method;
        fastcgi_param SERVER_PROTOCOL $server_protocol;
        fastcgi_param GATEWAY_INTERFACE CGI/1.1;
        fastcgi_param SERVER_SOFTWARE nginx;
        fastcgi_param HTTP_COOKIE $http_cookie;
      '';

      "@dashboard_login_redirect".extraConfig = ''
        return 302 /login/;
      '';

      # Internal-only, like the dashboard-auth-check above — reached via
      # auth_request from modules/self-update.nix's /update/trigger.
      "= /internal/dashboard-admin-check".extraConfig = ''
        internal;
        fastcgi_pass unix:/run/fcgiwrap-dashboard-login.sock;
        fastcgi_param SCRIPT_FILENAME ${lib.getExe adminCheckCgi};
        fastcgi_param REQUEST_METHOD $request_method;
        fastcgi_param SERVER_PROTOCOL $server_protocol;
        fastcgi_param GATEWAY_INTERFACE CGI/1.1;
        fastcgi_param SERVER_SOFTWARE nginx;
        fastcgi_param HTTP_COOKIE $http_cookie;
      '';

      # The login page itself and its CGI have to stay unauthenticated —
      # otherwise nobody could ever reach the form that lets them log in
      # in the first place.
      "^~ /login/".root = dashboardSite;

      "= /login/submit".extraConfig = ''
        fastcgi_pass unix:/run/fcgiwrap-dashboard-login.sock;
        fastcgi_param SCRIPT_FILENAME ${lib.getExe loginCgi};
        fastcgi_param REQUEST_METHOD $request_method;
        fastcgi_param CONTENT_TYPE $content_type;
        fastcgi_param CONTENT_LENGTH $content_length;
        fastcgi_param SERVER_PROTOCOL $server_protocol;
        fastcgi_param GATEWAY_INTERFACE CGI/1.1;
        fastcgi_param SERVER_SOFTWARE nginx;
      '';

      # Public (unauthenticated) — auth-nav.js polls this on every page,
      # including the public homepage, to decide what to render.
      "= /whoami".extraConfig = ''
        fastcgi_pass unix:/run/fcgiwrap-dashboard-login.sock;
        fastcgi_param SCRIPT_FILENAME ${lib.getExe whoamiCgi};
        fastcgi_param REQUEST_METHOD $request_method;
        fastcgi_param SERVER_PROTOCOL $server_protocol;
        fastcgi_param GATEWAY_INTERFACE CGI/1.1;
        fastcgi_param SERVER_SOFTWARE nginx;
        fastcgi_param HTTP_COOKIE $http_cookie;
      '';

      "= /logout".extraConfig = ''
        fastcgi_pass unix:/run/fcgiwrap-dashboard-login.sock;
        fastcgi_param SCRIPT_FILENAME ${lib.getExe logoutCgi};
        fastcgi_param REQUEST_METHOD $request_method;
        fastcgi_param SERVER_PROTOCOL $server_protocol;
        fastcgi_param GATEWAY_INTERFACE CGI/1.1;
        fastcgi_param SERVER_SOFTWARE nginx;
        fastcgi_param HTTP_COOKIE $http_cookie;
      '';
    };
  };
}
