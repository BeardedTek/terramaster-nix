{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.sso;
  domain = config.mySystem.domain;
  baseDn = lib.concatMapStringsSep "," (part: "dc=${part}") (lib.splitString "." domain);

  bindPasswordFile = "/etc/unix-ldap-login/ldap_password";

  # Same pinned reconciliation script modules/lldap.nix / modules/authelia.nix
  # / modules/dashboard-login.nix all use — here for a dedicated read-only
  # LDAP account this module needs to search for a user's DN by username
  # before nslcd re-binds as them. A plain LLDAP bind can only ever see its
  # own entry (confirmed the hard way, repeatedly, elsewhere in this repo)
  # — anonymous search fares no better. See modules/lldap.nix for the full
  # bootstrap.sh rationale.
  lldapBootstrapScript = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/lldap/lldap/48a0a8d961f32bd8e3263b202053ce49a6c94781/scripts/bootstrap.sh";
    sha256 = "1cf85qxdh5s5xk773i00wmv34cnd75nkl4x096jnyxbcp634wnmd";
  };
  ldapUserConfigs = pkgs.linkFarm "unix-ldap-login-bind-user-config" [
    {
      name = "unix-login.json";
      path = pkgs.writeText "unix-login.json" (builtins.toJSON {
        id = "unix-login";
        email = "unix-login@${domain}";
        password_file = bindPasswordFile;
        groups = [ "lldap_strict_readonly" ];
      });
    }
  ];
  ldapProvisionScript = pkgs.writeShellApplication {
    name = "unix-ldap-login-provision-bind-user";
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
in
{
  config = lib.mkIf cfg.enable {
    # Re-run on every activation, same reconciliation shape as
    # modules/authelia.nix's authelia-provision-ldap-bind-user /
    # modules/dashboard-login.nix's dashboard-login-provision-ldap-bind-user.
    systemd.services.unix-ldap-login-provision-bind-user = {
      description = "Ensure the Unix/PAM login's dedicated LDAP bind account exists in LLDAP";
      after = [ "lldap.service" "lldap-provision-users.service" ];
      requires = [ "lldap.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe ldapProvisionScript;
      };
    };

    # nslcd's preStart (nixpkgs' nixos/modules/config/ldap.nix, confirmed by
    # reading it directly) reads bind.passwordFile to build /run/nslcd/nslcd.conf
    # — and runs as the unprivileged "nslcd" user (same serviceConfig.User as
    # nslcd's own main process), not root. Same class of issue
    # modules/self-update.nix already solved for its own nginx-read htpasswd
    # file: the raw secret as delivered by secrets/extra-files won't
    # necessarily be readable by that user, so fix it explicitly on every
    # activation. `z` is a no-op if the file isn't there yet (first boot,
    # before the secret's been copied in).
    systemd.tmpfiles.rules = [
      "z ${bindPasswordFile} 0640 root nslcd - -"
    ];

    # Adds LDAP as an *additional* sufficient PAM auth source for
    # console/sudo/su — NOT a replacement. modules/users.nix's local
    # accounts (root, and everyone in mySystem.users) keep their own
    # password hashes untouched; NixOS's default PAM rule stack
    # (nixpkgs/nixos/modules/security/pam.nix, confirmed by reading it
    # directly for the nixos-26.05 channel this flake pins) puts pam_unix
    # ahead of pam_ldap, both "sufficient", so local logins work exactly as
    # before regardless of whether LLDAP is reachable — LDAP is a second
    # path in, not the only one. SSH is deliberately untouched: it's
    # key-only (mySystem.security.sshPasswordAuth defaults to false and
    # young doesn't override it), and PAM auth is never consulted for a
    # method SSH itself has turned off — this only affects local console
    # login and sudo/su prompts.
    #
    # nsswitch stays off: every current LLDAP account already has a
    # matching local Unix account (modules/lldap.nix mirrors
    # mySystem.users exactly), so there's no existing "LDAP-only" identity
    # for NSS to resolve. daemon.enable (nslcd / nss_pam_ldapd) isolates
    # the bind password to one process instead of every PAM-consuming
    # process reading it directly, and adds basic caching — the more
    # secure of the two modes users.ldap.daemon.enable offers, and the
    # right one now that a bind password is involved at all.
    users.ldap = {
      enable = true;
      loginPam = true;
      nsswitch = false;
      server = "ldap://127.0.0.1:3890/";
      base = baseDn;
      bind = {
        distinguishedName = "uid=unix-login,ou=people,${baseDn}";
        passwordFile = bindPasswordFile;
      };
      daemon.enable = true;
    };
  };
}
