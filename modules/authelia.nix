{ config, lib, pkgs, ... }:

let
  f = config.mySystem.features;
  cfg = f.sso.authelia;
  hostName = config.networking.hostName;
  domain = config.mySystem.domain;
  smtp = config.mySystem.smtp;
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
      enable = true; # Phase 2 test service, validated end-to-end on young
      policy = "one_factor";
    };
    radarr = { enable = true; policy = "one_factor"; }; # Phase 3
    jackett = { enable = true; policy = "one_factor"; }; # Phase 3
    seerr = { enable = true; policy = "one_factor"; }; # Phase 3
    qbittorrent = { enable = true; policy = "one_factor"; }; # Phase 3 — validate alongside the existing qb-headers middleware
    frigate = { enable = true; policy = "one_factor"; }; # Phase 3
    # No minio-console entry: it gets native OIDC (candidateOidcClients
    # below) instead of this plain ForwardAuth gate — MinIO has a real
    # OIDC client, unlike the gate-only apps above.
  };
  protectedServices = lib.mapAttrs
    (_: v: { inherit (v) policy; } // lib.optionalAttrs (v ? group) { inherit (v) group; })
    (lib.filterAttrs (_: v: v.enable) candidateProtectedServices);

  ruleFor = name: p: {
    domain = [ "${name}.${hostName}.${domain}" "${name}-${hostName}.nebula.${domain}" ];
    policy = p.policy;
  } // lib.optionalAttrs (p ? group) { subject = [ "group:${p.group}" ]; };

  # Second "hot-pluggable" table, same shape/spirit as
  # candidateProtectedServices above but for services that get real OIDC
  # client passthrough instead of a plain forward-auth gate. Adding one
  # later (e.g. MinIO) is one entry here plus that service's own module
  # reading its plaintext client secret from a matching /etc/authelia
  # secret file — see docs/DEPLOYMENT.md's secrets table.
  #
  # clientSecretHash is the argon2id *digest*, not the plaintext secret —
  # confirmed against Authelia's own `authelia crypto hash generate`
  # guide: modern Authelia (this flake's pin, 4.39.20) stores a hash here
  # and the plaintext only ever goes into the client application's own
  # config (modules/filebrowser.nix etc.), read from
  # /etc/authelia/oidc-clients/<name>_secret — never written into this
  # repo.
  candidateOidcClients = {
    filebrowser = {
      enable = true; # Phase 4
      clientSecretHash = "$argon2id$v=19$m=65536,t=3,p=4$aFblAB65E8E3yeHaBVln0w$FRqWs+EwgRIz/CHoEgHCQuPXQ3W07WEkg6fJuPRDiR4";
      # Must match modules/traefik.nix's `backends` key for this service,
      # NOT the client_id — confirmed the hard way: registering redirect
      # URIs under "filebrowser.<host>.<domain>" while the real Traefik
      # backend/vhost is named "files" (traefik.nix's `backends.files`)
      # got Authelia's own "redirect_uri does not match any of the OAuth
      # 2.0 Client's pre-registered redirect_uris" error, since
      # FileBrowser constructs its callback URL from whatever hostname it
      # was actually reached through.
      vhost = "files";
      # FileBrowser Quantum's OIDC callback route — confirmed against its
      # actual source (backend/http/oidc.go): @Router
      # /api/auth/oidc/callback.
      redirectPaths = [ "/api/auth/oidc/callback" ];
      scopes = [ "openid" "profile" "email" "groups" ];
    };
    "minio-console" = {
      enable = true; # Phase 4
      clientSecretHash = "$argon2id$v=19$m=65536,t=3,p=4$585RxXTFigxige43ZgJOdQ$nF5t4Vb2fI8vBd0Xc0IrUBO/EBrqwv5rG7FUUL4TRNw";
      vhost = "minio-console";
      # Confirmed against Authelia's own official MinIO integration guide
      # (authelia.com/integration/openid-connect/clients/minio/) — MinIO
      # doesn't retrieve claims the standard OIDC way, needing both this
      # specific extra client config AND a top-level claims_policies
      # entry below (claimsPolicies) that the client references.
      redirectPaths = [ "/oauth_callback" ];
      scopes = [ "openid" "profile" "email" "groups" ];
      policy = "two_factor"; # matches the two_factor tier this console already had under the (now-removed) ForwardAuth gate
      extra = {
        require_pkce = false;
        response_types = [ "code" ];
        grant_types = [ "authorization_code" ];
        access_token_signed_response_alg = "none";
        userinfo_signed_response_alg = "none";
        token_endpoint_auth_method = "client_secret_basic";
        claims_policy = "minio";
      };
    };
    homeassistant = {
      enable = true; # Phase 6
      # Public client (no client_secret) — hass-oidc-auth's own docs
      # explicitly recommend this over a confidential client for home
      # setups: "using properly configured redirect URLs + PKCE already
      # provides enough security... using a client secret introduces the
      # risk of it getting lost/stolen." Authelia enforces PKCE for
      # public clients automatically.
      public = true;
      vhost = "hass"; # matches modules/traefik.nix's backends.hass
      # hass-oidc-auth's fixed callback route — confirmed against its
      # own docs (docs/configuration.md): "<your HA URL>/auth/oidc/callback".
      redirectPaths = [ "/auth/oidc/callback" ];
      # groups_scope defaults to "groups" in hass-oidc-auth, matching
      # what's requested here — no override needed.
      scopes = [ "openid" "profile" "groups" ];
    };
  };
  oidcClients = lib.filterAttrs (_: v: v.enable) candidateOidcClients;

  oidcClientFor = name: c: {
    client_id = name;
    client_name = name;
    redirect_uris = lib.concatMap
      (path: [
        "https://${c.vhost}.${hostName}.${domain}${path}"
        "https://${c.vhost}-${hostName}.nebula.${domain}${path}"
      ])
      c.redirectPaths;
    scopes = c.scopes;
    authorization_policy = c.policy or "one_factor";
    public = c.public or false;
  } // (lib.optionalAttrs (!(c.public or false)) {
    client_secret = c.clientSecretHash;
  }) // (c.extra or { });

  # MinIO-specific workaround the official guide calls for — a named,
  # reusable claim set the "minio-console" client references via
  # extra.claims_policy above. Only emitted if that client is actually
  # enabled.
  claimsPolicies = lib.optionalAttrs (oidcClients ? "minio-console") {
    minio.id_token = [ "rat" "groups" "email" "email_verified" "alt_emails" "preferred_username" "name" ];
  };
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
        # mySystem.smtp unset (null) falls back to writing notifications
        # to a local file instead of emailing them — fine for
        # one-time-password-set-via-LLDAP-UI usage, but means password
        # resets and 2FA registration links never actually arrive by
        # mail. Talks to modules/smtp-relay.nix's loopback-only relay,
        # not the real upstream provider directly — no username/password
        # needed here at all, since that relay is unauthenticated for
        # local connections and holds the real credentials itself. See
        # modules/common.nix's mySystem.smtp for the full rationale.
        notifier = if smtp != null then {
          smtp = {
            address = "smtp://127.0.0.1:25";
            inherit (smtp) sender;
            # Authelia requires STARTTLS by default — fine for the real
            # upstream hop, but this connects to modules/smtp-relay.nix's
            # loopback-only OpenSMTPD, which doesn't offer TLS at all
            # (no eavesdropping risk on 127.0.0.1 to itself). Confirmed
            # the hard way: startup failed with "TLSMandatory, but target
            # host does not support STARTTLS" without this.
            disable_require_tls = true;
          };
        } else {
          filesystem.filename = "/var/lib/authelia-main/notifications.txt";
        };
      } // (lib.optionalAttrs (oidcClients != { }) {
        # Gated on oidcClients != {} so the oidc secret files below only
        # need to exist once something actually uses them — same
        # "nothing required until it's actually opted into" shape the
        # rest of this file follows.
        identity_providers.oidc = {
          clients = lib.mapAttrsToList oidcClientFor oidcClients;
        } // (lib.optionalAttrs (claimsPolicies != { }) {
          claims_policies = claimsPolicies;
        });
      });

      secrets = {
        jwtSecretFile = "/etc/authelia/jwt_secret";
        sessionSecretFile = "/etc/authelia/session_secret";
        storageEncryptionKeyFile = "/etc/authelia/storage_encryption_key";
      } // (lib.optionalAttrs (oidcClients != { }) {
        oidcHmacSecretFile = "/etc/authelia/oidc_hmac_secret";
        oidcIssuerPrivateKeyFile = "/etc/authelia/oidc_issuer_private_key.pem";
      });

      # LDAP bind password: no dedicated `secrets.*` option for it, so
      # this is Authelia's own documented `_FILE`-suffix env-var
      # convention instead — see
      # https://www.authelia.com/configuration/methods/secrets/. No SMTP
      # password needed here — see the notifier.smtp comment above.
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
