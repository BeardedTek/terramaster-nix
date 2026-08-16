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

  # Same OIDC_SECRETS_DIR override as modules/filebrowser.nix's own copy
  # of this — see its comment.
  oidcSecretsDir =
    let envOverride = builtins.getEnv "OIDC_SECRETS_DIR"; in
    if envOverride != "" then envOverride else "/persist/etc/authelia/oidc-clients";
  # Same file, same rationale as modules/filebrowser.nix's
  # oidcClientSecret — modules/authelia.nix hashes this exact file to
  # register the matching "minio-console" client, so the two can never
  # drift apart the way a hardcoded hash in the repo could.
  oidcClientSecret = lib.removeSuffix "\n" (builtins.readFile "${oidcSecretsDir}/minio-console_secret");

  # MinIO's OIDC claim-based policy assignment (CLAIM_NAME=groups below)
  # works purely by name matching: whatever value the "groups" claim
  # carries must be the name of an IAM policy that already exists on the
  # MinIO server, or login fails with "None of the given policies
  # (`admins`) are defined, credentials will not be generated" — no
  # separate "attach policy to group" step needed once it exists, MinIO
  # applies it automatically at login time. This is the LLDAP "admins"
  # group's own matching policy — full admin rights, equivalent to
  # MinIO's built-in consoleAdmin policy.
  adminsPolicyFile = pkgs.writeText "minio-admins-policy.json" (builtins.toJSON {
    Version = "2012-10-17";
    Statement = [
      { Effect = "Allow"; Action = [ "admin:*" ]; }
      { Effect = "Allow"; Action = [ "s3:*" ]; Resource = [ "arn:aws:s3:::*" ]; }
    ];
  });

  provisionAdminsPolicy = pkgs.writeShellApplication {
    name = "minio-provision-admins-policy";
    runtimeInputs = [ pkgs.minio-client pkgs.coreutils ];
    text = ''
      # MINIO_ROOT_USER/MINIO_ROOT_PASSWORD arrive via this unit's own
      # serviceConfig.EnvironmentFile (below), not a `source` of
      # /etc/minio/minio.env here — confirmed the hard way that
      # `mc alias set` kept failing even though the credentials in that
      # file were correct and minio.service itself was using them fine:
      # systemd's EnvironmentFile parsing and bash's `source` don't
      # necessarily strip quoting the same way, so a manually-`source`d
      # copy of the same file can silently diverge from what MinIO
      # itself actually sees as its own root password. Going through
      # EnvironmentFile here too guarantees both consumers parse the
      # exact same file the exact same way.

      # minio.service being "active" (this unit's own After=/Requires=)
      # only means the process has started, not that its HTTP listener is
      # bound yet — retry briefly rather than assuming it's immediately
      # reachable. Captures the real error instead of discarding it:
      # confirmed the hard way that swallowing it here made a genuine
      # credentials mismatch indistinguishable from minio just not being
      # up yet.
      attempt=0
      until output=$(mc alias set minio-admins-policy-provisioner http://127.0.0.1:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" 2>&1); do
        attempt=$((attempt + 1))
        if [ "$attempt" -ge 20 ]; then
          echo "mc alias set failed after 20 attempts against http://127.0.0.1:9000 — last error:" >&2
          echo "$output" >&2
          exit 1
        fi
        sleep 1
      done

      # `create` replaces the policy if it already exists (safe to
      # re-run on every activation — self-heals if the policy is ever
      # deleted, no marker file/one-time gate needed).
      mc admin policy create minio-admins-policy-provisioner admins ${adminsPolicyFile}
    '';
  };
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
      # Root credentials only — out-of-repo, same pattern as Traefik's
      # LINODE_TOKEN — see secrets/extra-files/persist/etc/minio/minio.env.example
      # and docs/DEPLOYMENT.md's secrets table. Missing the file is a
      # clean no-start (services.minio sets ConditionPathExists on it),
      # not a crash loop. The OIDC client secret used to be delivered as
      # one more manually-typed line in this same file — moved to
      # systemd.services.minio.environment below (Nix eval-time
      # readFile, same as MINIO_IDENTITY_OPENID_CLIENT_SECRET's own
      # comment) once that became install-time-generated instead of
      # manual, matching modules/filebrowser.nix's oidcClientSecret.
      rootCredentialsFile = "/etc/minio/minio.env";
    };

    # Non-secret OIDC settings — plain systemd Environment=, safe to
    # derive straight from Nix-known values (no drift risk the way a
    # manually-typed env-file line would have).
    #
    # CLAIM_NAME=groups + the matching Authelia claims_policy
    # (modules/authelia.nix) is the official, if awkward, Authelia<->MinIO
    # integration path — https://www.authelia.com/integration/openid-connect/clients/minio/
    # explicitly frames it as a workaround for MinIO not retrieving claims
    # the standard OIDC way. ROLE_POLICY is deliberately unset (setting
    # both role_policy and claim_name is a MinIO config error) — the
    # "admins" LLDAP group's claim value must match a real MinIO IAM
    # policy name for the mapping to actually grant anything; that
    # policy is provisioned automatically below (systemd.services.minio-
    # provision-admins-policy), not a manual follow-up.
    systemd.services.minio.environment = lib.optionalAttrs oidcEnabled {
      MINIO_IDENTITY_OPENID_CONFIG_URL = "https://auth.${hostName}.${domain}/.well-known/openid-configuration";
      MINIO_IDENTITY_OPENID_CLIENT_ID = "minio-console";
      MINIO_IDENTITY_OPENID_SCOPES = "openid,profile,email,groups";
      MINIO_IDENTITY_OPENID_REDIRECT_URI = "https://minio-console.${hostName}.${domain}/oauth_callback";
      MINIO_IDENTITY_OPENID_REDIRECT_URI_DYNAMIC = "off";
      MINIO_IDENTITY_OPENID_DISPLAY_NAME = "Authelia";
      MINIO_IDENTITY_OPENID_CLAIM_NAME = "groups";
      MINIO_IDENTITY_OPENID_CLAIM_USERINFO = "on";
      MINIO_IDENTITY_OPENID_CLIENT_SECRET = oidcClientSecret;
    };

    # No automatic ordering between a plain fileSystems mount and a
    # service that merely references paths under it — same class of gap
    # as modules/nfs.nix's RequiresMountsFor (see docs/TROUBLESHOOTING.md's
    # "NFS export script racing its own ZFS mounts"), just for a
    # dataDir/configDir path instead of an exports file.
    systemd.services.minio.unitConfig.RequiresMountsFor = [ "/rust/minio" ];

    # Runs whenever minio.service (re)starts — covers both a fresh
    # install with MinIO already enabled and MinIO being turned on for
    # the first time via a later rebuild, through the same mechanism, no
    # separate installer-time step needed. ConditionPathExists matches
    # services.minio's own gate on rootCredentialsFile: if root
    # credentials haven't been provisioned yet, this is a clean no-op
    # (minio.service itself won't be running either), not a crash loop —
    # same "missing/placeholder credential = clean no-op" posture as the
    # rest of this repo.
    systemd.services.minio-provision-admins-policy = lib.mkIf oidcEnabled {
      description = "Ensure MinIO has an IAM policy matching the 'admins' LLDAP group";
      after = [ "minio.service" ];
      requires = [ "minio.service" ];
      wantedBy = [ "minio.service" ];
      unitConfig.ConditionPathExists = "/etc/minio/minio.env";
      serviceConfig = {
        Type = "oneshot";
        # Same file minio.service itself consumes via
        # services.minio.rootCredentialsFile, and the same mechanism
        # (systemd EnvironmentFile=) rather than a bash `source` of it in
        # the script body — see provisionAdminsPolicy's own comment for
        # why that distinction turned out to matter.
        EnvironmentFile = "/etc/minio/minio.env";
        # Confirmed the hard way: without $HOME set, `mc` can't find its
        # config dir via Go's normal os.UserHomeDir() and falls back to
        # an NSS `getent passwd` lookup instead — which fails outright,
        # since systemd units don't get `getent` (glibc) on PATH by
        # default and none was added to runtimeInputs above. No User= is
        # set on this unit (runs as root), so /root is the right HOME.
        Environment = "HOME=/root";
        ExecStart = lib.getExe provisionAdminsPolicy;
      };
    };

    networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 9000 9001 ];
    networking.firewall.interfaces.${lanIf}.allowedTCPPorts = [ 9000 9001 ];
  };
}
