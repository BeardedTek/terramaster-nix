{ config, lib, pkgs, ... }:

let
  f = config.mySystem.features;
  cfg = f.sso.authelia;
  hostName = config.networking.hostName;
  domain = config.mySystem.domain;
  # "beardedtek.com" -> "dc=beardedtek,dc=com" — shared with
  # modules/lldap.nix so the two can never drift apart.
  baseDn = lib.concatMapStringsSep "," (part: "dc=${part}") (lib.splitString "." domain);
  ldapPasswordFile = "/etc/authelia/ldap_password";

  # Same pinned reconciliation script modules/lldap.nix uses for
  # mySystem.users — here just for Authelia's own dedicated LDAP bind
  # account, kept separate from that module's human-user sync since it's
  # this module's own credential to own (it already manages
  # ldapPasswordFile). See modules/lldap.nix for the full rationale.
  bootstrapScript = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/lldap/lldap/48a0a8d961f32bd8e3263b202053ce49a6c94781/scripts/bootstrap.sh";
    sha256 = "1cf85qxdh5s5xk773i00wmv34cnd75nkl4x096jnyxbcp634wnmd";
  };

  # password_file (unlike modules/lldap.nix's human-user configs, which
  # deliberately omit it) — this is a machine credential Authelia itself
  # needs to know deterministically, not a human's self-chosen password,
  # so it's fine (expected, even) for this to be reasserted every
  # activation.
  userConfigs = pkgs.linkFarm "authelia-ldap-bind-user-config" [
    {
      name = "authelia.json";
      path = pkgs.writeText "authelia.json" (builtins.toJSON {
        id = "authelia";
        email = "authelia@${domain}";
        password_file = ldapPasswordFile;
        # Without this, the account can bind fine but can only see its
        # own entry — confirmed the hard way via a manual ldapsearch: a
        # plain LLDAP user has no read access to the rest of the
        # directory by default. lldap_strict_readonly is LLDAP's own
        # built-in group for exactly this (a service account that needs
        # to search/read everyone, not a full admin) — see bootstrap.sh's
        # own protected-groups list (lldap_admin, lldap_password_manager,
        # lldap_strict_readonly), which is where this name comes from.
        groups = [ "lldap_strict_readonly" ];
      });
    }
  ];

  provisionScript = pkgs.writeShellApplication {
    name = "authelia-provision-ldap-bind-user";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.jo pkgs.bash pkgs.coreutils ];
    text = ''
      export LLDAP_URL="http://127.0.0.1:17170"
      export LLDAP_ADMIN_USERNAME="admin"
      export LLDAP_ADMIN_PASSWORD_FILE="/etc/lldap/ldap_user_pass"
      export USER_CONFIGS_DIR="${userConfigs}"
      export LLDAP_SET_PASSWORD_PATH="${lib.getExe' pkgs.lldap "lldap_set_password"}"
      bash ${bootstrapScript}
    '';
  };

  # The one "hot-pluggable" table this whole design is built around —
  # protecting a new service later (present or future, e.g. a
  # hypothetical modules/vaultwarden.nix) is one line here plus its
  # normal modules/traefik.nix backend entry; nothing else to touch.
  #
  # `enable` here is a deliberate, separate on/off from each service's
  # own mySystem.features.<x>.enable — SSO-gating a service is a
  # conscious, individually-validated decision (see the phased rollout
  # in the SSO plan), not something that should silently switch on just
  # because the backend itself happens to be enabled. Flip these on one
  # at a time, phase by phase, once each has been click-tested.
  candidateProtectedServices = {
    sonarr = {
      enable = true; # Phase 2 test service
      policy = "one_factor";
    };
    radarr = { enable = false; policy = "one_factor"; };
    jackett = { enable = false; policy = "one_factor"; };
    seerr = { enable = false; policy = "one_factor"; };
    qbittorrent = { enable = false; policy = "one_factor"; }; # validate alongside the existing qb-headers middleware once flipped on
    frigate = { enable = false; policy = "one_factor"; };
    "minio-console" = { enable = false; policy = "two_factor"; group = "admins"; };
  };
  protectedServices = lib.mapAttrs
    (_: v: { inherit (v) policy; } // lib.optionalAttrs (v ? group) { inherit (v) group; })
    (lib.filterAttrs (_: v: v.enable) candidateProtectedServices);

  ruleFor = name: p: {
    domain = [ "${name}.${hostName}.${domain}" "${name}-${hostName}.nebula.${domain}" ];
    policy = p.policy;
  } // lib.optionalAttrs (p ? group) { subject = [ "group:${p.group}" ]; };
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = f.sso.enable;
        message = "mySystem.features.sso.authelia.enable requires mySystem.features.sso.enable (LLDAP) too.";
      }
    ];

    mySystem.sso.protectedServices = protectedServices;

    services.authelia.instances.main = {
      enable = true;

      # Real Authelia config.yml, written declaratively — see
      # https://github.com/authelia/authelia/blob/master/config.template.yml.
      # `settings.session.cookies[].domain = "beardedtek.com"` is meant to
      # cover both this flake's domain shapes
      # (<svc>.${hostName}.beardedtek.com and
      # <svc>-${hostName}.nebula.beardedtek.com — both subdomains of
      # beardedtek.com) under one session. UNVALIDATED until Phase 2's
      # Sonarr test actually runs both variants through a browser — if it
      # doesn't hold up, split into two services.authelia.instances (one
      # per domain scheme) before protecting anything past Sonarr.
      settings = {
        theme = "auto";

        session.cookies = [{
          inherit domain;
          authelia_url = "https://auth.${hostName}.${domain}";
        }];

        # implementation = "lldap" mainly relaxes validation for features
        # LLDAP doesn't support (account expiration/lockout attributes) —
        # it does NOT auto-populate users_filter/groups_filter/attributes
        # the way I'd first assumed (confirmed the hard way: Authelia
        # refused to start with "option 'users_filter' is required" even
        # with implementation set). This is the exact block Authelia's
        # own LLDAP integration docs recommend —
        # https://www.authelia.com/integration/ldap/lldap/ — with our
        # base_dn substituted in. ou=people/ou=groups are LLDAP's own
        # fixed internal schema, not something lldap_config.toml
        # configures, so they're safe to hardcode here.
        authentication_backend.ldap = {
          implementation = "lldap";
          address = "ldap://127.0.0.1:3890";
          base_dn = baseDn;
          additional_users_dn = "ou=people";
          additional_groups_dn = "ou=groups";
          # Dedicated bind account, distinct from LLDAP's own bootstrap
          # admin — least-privilege, same "unprivileged dedicated user"
          # idiom self-update.nix's nas-update and filebrowser.nix's
          # filebrowser system users already use, just inside LLDAP's own
          # accounts rather than a Unix user.
          user = "uid=authelia,ou=people,${baseDn}";
          username_attribute = "uid";
          display_name_attribute = "cn";
          mail_attribute = "mail";
          group_name_attribute = "cn";
          # {username_attribute}/{input}/{dn} are Authelia's own template
          # placeholders (substituted by Authelia at runtime), not Nix
          # interpolation — plain single braces, left untouched by Nix.
          users_filter = "(&(|({username_attribute}={input})({mail_attribute}={input}))(objectClass=person))";
          groups_filter = "(&(member={dn})(objectClass=groupOfNames))";
        };

        access_control = {
          default_policy = "deny";
          rules = [
            # Dashboard: homepage and the /update page/status endpoint stay
            # fully public, unchanged from today — see modules/self-update.nix
            # for why /update/status is deliberately unauthenticated.
            # /update/trigger itself is intentionally NOT listed here; see
            # the SSO plan's "Dashboard /update step-up" section — it's
            # layered behind the existing htpasswd gate instead of an
            # Authelia policy tier, once that phase lands.
            {
              domain = [ "${hostName}.${domain}" "${hostName}.nebula.${domain}" ];
              policy = "bypass";
            }
          ] ++ (lib.mapAttrsToList ruleFor protectedServices);
        };

        storage.local.path = "/var/lib/authelia-main/db.sqlite3";
        notifier.filesystem.filename = "/var/lib/authelia-main/notifications.txt"; # no SMTP set up yet — password-reset emails won't send; fine for one-time-password-set-via-LLDAP-UI usage for now
      };

      secrets = {
        jwtSecretFile = "/etc/authelia/jwt_secret";
        sessionSecretFile = "/etc/authelia/session_secret";
        storageEncryptionKeyFile = "/etc/authelia/storage_encryption_key";
      };

      # LDAP bind password: no dedicated `secrets.*` option for it, so
      # this is Authelia's own documented `_FILE`-suffix env-var
      # convention instead — see
      # https://www.authelia.com/configuration/methods/secrets/.
      environmentVariables = {
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = ldapPasswordFile;
      };
    };

    # Re-run on every activation, same reconciliation shape as
    # modules/lldap.nix's lldap-provision-users — ensures the LDAP side
    # of this bind account always matches ldapPasswordFile, so a rotated
    # secret takes effect on the next rebuild with no manual step in
    # LLDAP's own UI.
    systemd.services.authelia-provision-ldap-bind-user = {
      description = "Ensure Authelia's dedicated LDAP bind account exists in LLDAP";
      after = [ "lldap.service" "lldap-provision-users.service" ];
      requires = [ "lldap.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe provisionScript;
      };
    };
  };
}
