{ config, pkgs, lib, ... }:

let
  f = config.mySystem.features;
  acqEnabled = name: f.mediaAcquisition.enable && f.mediaAcquisition.${name}.enable;

  # openFirewall opens a service's raw port directly, on top of whatever
  # Traefik already routes — harmless for an unprotected service, but a
  # complete bypass of Authelia's ForwardAuth gate for one that's SSO-
  # protected (confirmed the hard way: this is exactly how the Sonarr
  # test service would have had zero effective auth via direct IP:port,
  # despite being gated at the Traefik layer). Keyed the same as
  # modules/traefik.nix's `backends` / mySystem.sso.protectedServices, so
  # a service's direct-port exposure automatically tracks whether it's
  # SSO-gated — no separate flag to remember to flip.
  protected = config.mySystem.sso.protectedServices;
  directlyReachable = name: !(protected ? ${name});

  # Jellyfin gets native LDAP auth (the official jellyfin/jellyfin-plugin-
  # ldapauth, Tier A per the SSO plan) rather than the ForwardAuth gate —
  # not in mySystem.sso.protectedServices, same reasoning as FileBrowser/
  # MinIO's own native-OIDC treatment: direct IP access still hits a real
  # login (LDAP or Jellyfin's own local accounts), no bypass concern.
  ldapEnabled = f.sso.enable;
  domain = config.mySystem.domain;
  baseDn = lib.concatMapStringsSep "," (part: "dc=${part}") (lib.splitString "." domain);
  jellyfinDataDir = "/var/lib/jellyfin";

  ldapAuthPluginVersion = "23.0.0.0";
  ldapAuthPlugin = pkgs.fetchzip {
    url = "https://github.com/jellyfin/jellyfin-plugin-ldapauth/releases/download/v23/ldap-authentication_${ldapAuthPluginVersion}.zip";
    sha256 = "sha256-yuOAJTj+QKj6bxlJ+irDE2BjxH1ZbsgAri7fauDMOBM="; # fetchzip hashes the *unpacked* tree, not the raw zip — verified with a real test build, not nix-prefetch-url's (wrong-for-this-case) raw-file hash
    stripRoot = false; # zip has no wrapping directory — DLLs/meta.json sit directly at its root
  };

  # Same pinned reconciliation script modules/lldap.nix / modules/authelia.nix
  # use — here just for Jellyfin's own dedicated LDAP bind account. See
  # modules/lldap.nix for the full rationale.
  lldapBootstrapScript = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/lldap/lldap/48a0a8d961f32bd8e3263b202053ce49a6c94781/scripts/bootstrap.sh";
    sha256 = "1cf85qxdh5s5xk773i00wmv34cnd75nkl4x096jnyxbcp634wnmd";
  };
  jellyfinLdapBindPasswordFile = "/etc/jellyfin/ldap_bind_password";
  jellyfinLdapUserConfigs = pkgs.linkFarm "jellyfin-ldap-bind-user-config" [
    {
      name = "jellyfin.json";
      path = pkgs.writeText "jellyfin.json" (builtins.toJSON {
        id = "jellyfin";
        email = "jellyfin@${domain}";
        password_file = jellyfinLdapBindPasswordFile;
        groups = [ "lldap_strict_readonly" ]; # needs to search for/see any person entry, same as Authelia's own bind account
      });
    }
  ];
  jellyfinLdapProvisionScript = pkgs.writeShellApplication {
    name = "jellyfin-provision-ldap-bind-user";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.jo pkgs.bash pkgs.coreutils ];
    text = ''
      export LLDAP_URL="http://127.0.0.1:17170"
      export LLDAP_ADMIN_USERNAME="admin"
      export LLDAP_ADMIN_PASSWORD_FILE="/etc/lldap/ldap_user_pass"
      export USER_CONFIGS_DIR="${jellyfinLdapUserConfigs}"
      export LLDAP_SET_PASSWORD_PATH="${lib.getExe' pkgs.lldap "lldap_set_password"}"
      bash ${lldapBootstrapScript}
    '';
  };
in
{
  config = lib.mkMerge [
    { users.groups.mediagroup = { }; }

    (lib.mkIf f.jellyfin.enable {
      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver     # iHD VA-API driver
          intel-compute-runtime  # OpenCL runtime — required for tone mapping
          vpl-gpu-rt             # Intel VPL runtime — modern Quick Sync
        ];
      };
      # hardware.graphics.extraPackages above merges every listed
      # package's whole output tree into /run/opengl-driver (a plain
      # pkgs.buildEnv, confirmed by reading nixos/modules/hardware/
      # graphics.nix directly — it's not OpenCL-aware) — so
      # intel-compute-runtime's ICD file really does land at
      # /run/opengl-driver/etc/OpenCL/vendors/intel-neo.icd. But the
      # OpenCL ICD loader (ocl-icd, which ffmpeg links against) only
      # ever searches the real /etc/OpenCL/vendors — nothing points
      # there at the merged one by default. Confirmed the hard way via
      # `clinfo` reporting zero platforms despite the runtime being
      # correctly installed: HDR tone-mapping (tonemap_opencl) needs
      # this, on both the QSV and plain VA-API transcode paths.
      environment.etc."OpenCL/vendors".source = "/run/opengl-driver/etc/OpenCL/vendors";
      services.jellyfin = {
        enable = true;
        openFirewall = directlyReachable "jellyfin";
        cacheDir = "/var/lib/jellyfin/cache";
      };
      users.users.jellyfin.extraGroups = [ "video" "render" "mediagroup" ];
    })

    (lib.mkIf (f.jellyfin.enable && ldapEnabled) {
      # jellyfin-ldap-plugin-setup (below) runs as the fixed `jellyfin`
      # system user and reads this delivered secret directly — same
      # pattern, same fix, as modules/unix-ldap-login.nix's own
      # bindPasswordFile `z` rule: a plain `chmod 600` (root-only, e.g.
      # from the installer wizard) leaves it unreadable by that user.
      # `z` is a no-op if the file isn't there yet (first boot, before
      # the secret's been copied in).
      systemd.tmpfiles.rules = [
        "z ${jellyfinLdapBindPasswordFile} 0640 root jellyfin - -"
      ];

      # Re-run on every activation, same reconciliation shape as
      # modules/lldap.nix's lldap-provision-users / modules/authelia.nix's
      # authelia-provision-ldap-bind-user.
      systemd.services.jellyfin-provision-ldap-bind-user = {
        description = "Ensure Jellyfin's dedicated LDAP bind account exists in LLDAP";
        after = [ "lldap.service" "lldap-provision-users.service" ];
        requires = [ "lldap.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe jellyfinLdapProvisionScript;
        };
      };

      # Installs the official jellyfin/jellyfin-plugin-ldapauth plugin and
      # writes its config once — guarded on the config file not already
      # existing, same "bootstrap once, then the app's own state is
      # authoritative" idiom modules/filebrowser.nix's filebrowser-setup
      # already uses. Without this guard, every rebuild would wipe
      # LdapUsers (the plugin's own LDAP-uid-to-Jellyfin-account linkage,
      # not present in this minimal config) and any other setting changed
      # later through Jellyfin's own admin UI.
      #
      # Admin auto-detection (LdapAdminFilter) is deliberately left unset:
      # the plugin's own admin-check expects a filter matching the
      # authenticating user's *own* LDAP entry (e.g. a memberOf-style
      # back-reference), which LLDAP's groupOfNames/member schema doesn't
      # expose on person entries — confirmed by Authelia needing its own
      # separate group-search step (modules/authelia.nix's groups_filter)
      # instead of a single-entry filter for the exact same reason. Set
      # Jellyfin admin status manually through its own UI for whichever
      # accounts need it, same manual-follow-up shape as MinIO's "admins"
      # IAM policy.
      systemd.services.jellyfin-ldap-plugin-setup = {
        description = "Install and configure the Jellyfin LDAP-Auth plugin";
        before = [ "jellyfin.service" ];
        requiredBy = [ "jellyfin.service" ];
        after = [ "jellyfin-provision-ldap-bind-user.service" ];
        requires = [ "jellyfin-provision-ldap-bind-user.service" ];
        unitConfig.ConditionPathExists = "!${jellyfinDataDir}/plugins/configurations/LDAP-Auth.xml";
        serviceConfig = {
          Type = "oneshot";
          User = "jellyfin";
          Group = "jellyfin";
        };
        script = ''
          set -euo pipefail
          plugin_dir="${jellyfinDataDir}/plugins/ldap-auth_${ldapAuthPluginVersion}"
          mkdir -p "$plugin_dir"
          cp -f ${ldapAuthPlugin}/*.dll ${ldapAuthPlugin}/meta.json "$plugin_dir/"
          # Nix store files are read-only (444, no write bit for anyone) —
          # cp preserves that even though jellyfin now owns the copy.
          # Jellyfin itself writes to meta.json at runtime (recording
          # plugin state) — confirmed the hard way: "Access to the path
          # '.../meta.json' is denied" crashed the whole server at startup.
          chmod u+w "$plugin_dir"/*

          config_dir="${jellyfinDataDir}/plugins/configurations"
          mkdir -p "$config_dir"
          bind_password=$(cat ${jellyfinLdapBindPasswordFile})
          cat > "$config_dir/LDAP-Auth.xml" <<EOF
          <?xml version="1.0" encoding="utf-8"?>
          <PluginConfiguration>
            <LdapServer>127.0.0.1</LdapServer>
            <LdapPort>3890</LdapPort>
            <UseSsl>false</UseSsl>
            <UseStartTls>false</UseStartTls>
            <LdapBindUser>uid=jellyfin,ou=people,${baseDn}</LdapBindUser>
            <LdapBindPassword>$bind_password</LdapBindPassword>
            <LdapBaseDn>ou=people,${baseDn}</LdapBaseDn>
            <LdapSearchFilter>(objectClass=person)</LdapSearchFilter>
            <LdapSearchAttributes>uid, cn, mail</LdapSearchAttributes>
            <CreateUsersFromLdap>true</CreateUsersFromLdap>
            <LdapUidAttribute>uid</LdapUidAttribute>
            <LdapUsernameAttribute>uid</LdapUsernameAttribute>
          </PluginConfiguration>
          EOF
        '';
      };
    })

    (lib.mkIf (acqEnabled "sonarr") {
      services.sonarr.enable = true;
      services.sonarr.openFirewall = directlyReachable "sonarr";
      users.users.sonarr.extraGroups = [ "mediagroup" ];
    })

    (lib.mkIf (acqEnabled "radarr") {
      services.radarr.enable = true;
      services.radarr.openFirewall = directlyReachable "radarr";
      users.users.radarr.extraGroups = [ "mediagroup" ];
    })

    (lib.mkIf (acqEnabled "jackett") {
      services.jackett.enable = true;
      services.jackett.openFirewall = directlyReachable "jackett";
    })

    (lib.mkIf (acqEnabled "qbittorrent") {
      # Deliberately NOT using services.qbittorrent.serverConfig for anything —
      # the module's ExecStartPre unconditionally overwrites the *entire*
      # qBittorrent.conf from the Nix-declared value on every service restart
      # once serverConfig is non-empty, discarding anything qBittorrent itself
      # had written since (WebUI password changes, other settings) — confirmed
      # the hard way: a password set via the WebUI got silently reverted on the
      # next `nixos-rebuild switch`. Its Host-header validation (the reason
      # serverConfig was tried here) is worked around instead on the Traefik
      # side — see modules/traefik.nix.
      services.qbittorrent.enable = true;
      services.qbittorrent.openFirewall = directlyReachable "qbittorrent";
      users.users.qbittorrent.extraGroups = [ "mediagroup" ];
    })

    (lib.mkIf (acqEnabled "seerr") {
      services.seerr = {
        enable = true;
        openFirewall = directlyReachable "seerr";
      };
      users.users.seerr = {
        isSystemUser = true;
        group = "seerr";
        extraGroups = [ "mediagroup" ];
      };
      users.groups.seerr = { };
      systemd.services.seerr.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "seerr";
        Group = "seerr";
      };
    })
  ];
}
