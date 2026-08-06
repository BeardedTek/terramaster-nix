{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.sso;
  lanIf = config.mySystem.lanInterface;
  domain = config.mySystem.domain;
  # "beardedtek.com" -> "dc=beardedtek,dc=com" — shared with
  # modules/authelia.nix so the two can never drift apart.
  baseDn = lib.concatMapStringsSep "," (part: "dc=${part}") (lib.splitString "." domain);

  adminPassFile = "/etc/lldap/ldap_user_pass";
  httpPort = 17170;

  # LLDAP's own official reconciliation script — reads JSON files
  # describing the desired users/groups and diffs them against LLDAP's
  # GraphQL API (create/update, warn-but-don't-delete on anything not
  # declared, since DO_CLEANUP* isn't set below). Pinned to the exact
  # tag matching nixpkgs' lldap package version (0.6.3) so the script
  # and server are guaranteed to speak the same GraphQL schema — see
  # https://github.com/lldap/lldap/blob/v0.6.3/scripts/bootstrap.sh and
  # its companion doc, example_configs/bootstrap/bootstrap.md.
  bootstrapScript = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/lldap/lldap/48a0a8d961f32bd8e3263b202053ce49a6c94781/scripts/bootstrap.sh";
    sha256 = "1cf85qxdh5s5xk773i00wmv34cnd75nkl4x096jnyxbcp634wnmd";
  };

  # One JSON file per mySystem.users entry — the same list modules/users.nix
  # provisions as Unix accounts, now also the source of truth for LDAP
  # accounts. wheel = true maps to the "admins" LDAP group (matches
  # modules/authelia.nix's use of group:admins for the two_factor tier).
  # No "password"/"password_file" field: bootstrap.sh only ever touches a
  # user's password when one of those is present (confirmed by reading
  # the script directly) — omitting it entirely means a user's own
  # self-service password (set through LLDAP's web UI) is never reset on
  # a later rebuild.
  userConfigs = pkgs.linkFarm "lldap-user-configs" (
    map
      (u: {
        name = "${u.name}.json";
        path = pkgs.writeText "${u.name}.json" (builtins.toJSON {
          id = u.name;
          email = "${u.name}@${domain}";
          groups = lib.optionals u.wheel [ "admins" ];
        });
      })
      config.mySystem.users
  );

  groupConfigs = pkgs.linkFarm "lldap-group-configs" [
    { name = "admins.json"; path = pkgs.writeText "admins.json" (builtins.toJSON { name = "admins"; }); }
  ];

  provisionScript = pkgs.writeShellApplication {
    name = "lldap-provision-users";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.jo pkgs.bash pkgs.coreutils ];
    text = ''
      export LLDAP_URL="http://127.0.0.1:${toString httpPort}"
      export LLDAP_ADMIN_USERNAME="admin"
      export LLDAP_ADMIN_PASSWORD_FILE="${adminPassFile}"
      export USER_CONFIGS_DIR="${userConfigs}"
      export GROUP_CONFIGS_DIR="${groupConfigs}"
      export LLDAP_SET_PASSWORD_PATH="${lib.getExe' pkgs.lldap "lldap_set_password"}"
      bash ${bootstrapScript}
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    # lldap.service runs with DynamicUser=true, User=Group="lldap" — that
    # name is only resolvable via nss-systemd *while the service is
    # actually running* (confirmed the hard way: `getent group lldap`
    # returns nothing, and a `systemd-tmpfiles` `z ... lldap - -` rule
    # fails outright with "Failed to resolve group 'lldap': Unknown
    # group", whenever the service isn't up). Since this file has to be
    # readable *before* lldap can start at all, the group-ownership fix
    # every other LDAP-bind secret in this repo uses (see
    # modules/unix-ldap-login.nix's own `z` rule) is a deadlock here
    # specifically — chown to a name that only exists once the thing
    # trying to read the file has already started. World-readable is the
    # pragmatic way out (the directory itself is already 0755, so this
    # doesn't newly expose anything beyond "any local process on this
    # box" that wasn't already true of the directory listing); a
    # `LoadCredential=`-based module rewrite would avoid that but is a
    # bigger change, deliberately not made here.
    systemd.tmpfiles.rules = [
      "z ${adminPassFile} 0644 root root - -"
    ];

    services.lldap = {
      enable = true;
      # Freeform passthrough straight to lldap_config.toml — see
      # https://github.com/lldap/lldap/blob/main/lldap_config.docker_template.toml.
      settings = {
        ldap_base_dn = baseDn;
        ldap_port = 3890;
        http_port = httpPort;
        # A literal (Nix-visible) *path*, not the secret itself — the
        # module's own assertion specifically checks for this setting
        # (or the LLDAP_LDAP_USER_PASS_FILE env var) at eval time, so
        # putting the raw password inside a plain environmentFile
        # doesn't satisfy it. The file's contents are out-of-repo, same
        # pattern as Traefik's LINODE_TOKEN — see
        # secrets/extra-files/persist/etc/lldap/ldap_user_pass.example
        # and docs/DEPLOYMENT.md's secrets table. No jwt_secret_file set
        # here: the module bootstraps and persists its own random one
        # under /var/lib/lldap if none is given.
        ldap_user_pass_file = adminPassFile;
      };
    };

    # force_ldap_user_pass_reset stays at its default (false, one-time
    # bootstrap only) — same "credentials file sets the initial value,
    # the app's own UI/state is authoritative after that" idiom
    # modules/filebrowser.nix's admin.env already uses. Silencing the
    # module's own warning about that tradeoff since it's a deliberate,
    # already-considered choice, not an oversight.
    services.lldap.silenceForceUserPassResetWarning = true;

    # Re-run on every activation (no ConditionPathExists guard) so
    # mySystem.users stays the actual source of truth for LDAP accounts,
    # not just Unix ones — adding a user or flipping wheel there is
    # enough, no manual step in LLDAP's own UI needed. Only reuses the
    # same admin password already delivered for LLDAP's own bootstrap
    # above — no new secret to manage. DO_CLEANUP* is deliberately left
    # at its default (false): removing someone from mySystem.users warns
    # instead of deleting their LDAP account, matching this repo's
    # general posture of not automating destructive actions.
    systemd.services.lldap-provision-users = {
      description = "Reconcile LLDAP users/groups against mySystem.users";
      after = [ "lldap.service" ];
      requires = [ "lldap.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe provisionScript;
      };
    };

    # LAN-only, deliberately never routed through Traefik or exposed on
    # nebula1: this is the identity source of truth everything else
    # (Authelia, eventually PAM) depends on — putting it behind the thing
    # that depends on it is a circular bootstrap risk, and it should stay
    # reachable even if Traefik/Authelia is broken. Same reasoning as
    # modules/traefik.nix's lan-local entrypoint existing specifically so
    # the dashboard stays reachable if TLS/cert issuance breaks.
    networking.firewall.interfaces.${lanIf}.allowedTCPPorts = [
      3890 # ldap
      httpPort # admin web UI
    ];
  };
}
