{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.minio;
  lanIf = config.mySystem.lanInterface;
  hostName = config.networking.hostName;
  domain = config.mySystem.domain;

  # Native OIDC (Tier A per the SSO plan), not the Traefik ForwardAuth
  # gate the media-acquisition services use — so unlike Frigate/Sonarr,
  # there's no direct-IP bypass concern to close a firewall port over:
  # MinIO's own console always requires its own login (OIDC or root
  # credentials) regardless of access path, the same reasoning
  # modules/filebrowser.nix's OIDC integration already relies on.
  oidcEnabled = config.mySystem.features.sso.authelia.enable;
in
{
  config = lib.mkIf cfg.enable {
    services.minio = {
      enable = true;
      package = pkgs.callPackage ../pkgs/minio.nix { };
      listenAddress = ":9000";
      consoleAddress = ":9001";
      # A dedicated ZFS dataset (fileSystems."/rust/minio", declared per
      # host — see hosts/terramaster/young/configuration.nix), not the
      # module's own /var/lib/minio default. Object storage is bulk data,
      # the same category as rust/media and rust/data, not small app
      # state — and, unlike /var/lib/minio (which would sit under
      # /persist via an impermanence bind-mount), a real ZFS fileSystems
      # entry is mounted directly at boot with no bind-mount indirection,
      # sidestepping the "freshly-created persistence bind-mount has the
      # wrong ownership" race entirely (see docs/TROUBLESHOOTING.md) —
      # confirmed the hard way: minio's own tmpfiles rule for the default
      # /var/lib/minio/{data,config} lost that exact race on first
      # deploy, and MinIO refused to start ("file access denied").
      dataDir = [ "/rust/minio/data" ];
      configDir = "/rust/minio/config";
      # Root credentials are out-of-repo, same pattern as Traefik's
      # LINODE_TOKEN — see secrets/extra-files/persist/etc/minio/minio.env.example
      # and docs/DEPLOYMENT.md's secrets table. Missing the file is a
      # clean no-start (services.minio sets ConditionPathExists on it),
      # not a crash loop.
      # MINIO_IDENTITY_OPENID_CLIENT_SECRET (the one genuinely secret OIDC
      # value below) is delivered as one more line in this same file, not
      # a separate one — services.minio has no generic settings/environment
      # passthrough to hang a second EnvironmentFile off declaratively
      # without relying on NixOS's list-merge behavior for this specific
      # option, and this file is already exactly "secrets MinIO reads at
      # its own startup." See docs/DEPLOYMENT.md's secrets table.
      rootCredentialsFile = "/etc/minio/minio.env";
    };

    # Non-secret OIDC settings — plain systemd Environment=, safe to
    # derive straight from Nix-known values (no drift risk the way a
    # manually-typed env-file line would have). The secret
    # (MINIO_IDENTITY_OPENID_CLIENT_SECRET) is NOT here; see
    # rootCredentialsFile's comment above.
    #
    # CLAIM_NAME=groups + the matching Authelia claims_policy
    # (modules/authelia.nix) is the official, if awkward, Authelia<->MinIO
    # integration path — https://www.authelia.com/integration/openid-connect/clients/minio/
    # explicitly frames it as a workaround for MinIO not retrieving claims
    # the standard OIDC way. ROLE_POLICY is deliberately unset (setting
    # both role_policy and claim_name is a MinIO config error) — the
    # "admins" LLDAP group's claim value must match a real MinIO IAM
    # policy name for the mapping to actually grant anything; creating
    # that policy in MinIO itself is a manual follow-up, not yet
    # automated here.
    systemd.services.minio.environment = lib.optionalAttrs oidcEnabled {
      MINIO_IDENTITY_OPENID_CONFIG_URL = "https://auth.${hostName}.${domain}/.well-known/openid-configuration";
      MINIO_IDENTITY_OPENID_CLIENT_ID = "minio-console";
      MINIO_IDENTITY_OPENID_SCOPES = "openid,profile,email,groups";
      MINIO_IDENTITY_OPENID_REDIRECT_URI = "https://minio-console.${hostName}.${domain}/oauth_callback";
      MINIO_IDENTITY_OPENID_REDIRECT_URI_DYNAMIC = "off";
      MINIO_IDENTITY_OPENID_DISPLAY_NAME = "Authelia";
      MINIO_IDENTITY_OPENID_CLAIM_NAME = "groups";
      MINIO_IDENTITY_OPENID_CLAIM_USERINFO = "on";
    };

    # No automatic ordering between a plain fileSystems mount and a
    # service that merely references paths under it — same class of gap
    # as modules/nfs.nix's RequiresMountsFor (see docs/TROUBLESHOOTING.md's
    # "NFS export script racing its own ZFS mounts"), just for a
    # dataDir/configDir path instead of an exports file.
    systemd.services.minio.unitConfig.RequiresMountsFor = [ "/rust/minio" ];

    networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 9000 9001 ];
    networking.firewall.interfaces.${lanIf}.allowedTCPPorts = [ 9000 9001 ];
  };
}
