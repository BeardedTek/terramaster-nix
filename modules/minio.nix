{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.minio;
  lanIf = config.mySystem.lanInterface;

  # 9000 (S3 API) always stays open regardless — most S3 clients (rclone,
  # s3cmd, etc.) can't participate in a browser-cookie SSO flow at all, so
  # it was never a candidate for mySystem.sso.protectedServices in the
  # first place. 9001 (the browser admin console) is exactly what
  # "minio-console" in modules/authelia.nix's candidateProtectedServices
  # is meant to gate — leaving it directly open would let anyone bypass
  # that two_factor policy via http://<ip>:9001. See modules/media-stack.nix
  # for the same pattern applied to the media-acquisition services.
  consoleDirectlyReachable = !(config.mySystem.sso.protectedServices ? "minio-console");
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
      rootCredentialsFile = "/etc/minio/minio.env";
    };

    # No automatic ordering between a plain fileSystems mount and a
    # service that merely references paths under it — same class of gap
    # as modules/nfs.nix's RequiresMountsFor (see docs/TROUBLESHOOTING.md's
    # "NFS export script racing its own ZFS mounts"), just for a
    # dataDir/configDir path instead of an exports file.
    systemd.services.minio.unitConfig.RequiresMountsFor = [ "/rust/minio" ];

    networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 9000 ] ++ lib.optionals consoleDirectlyReachable [ 9001 ];
    networking.firewall.interfaces.${lanIf}.allowedTCPPorts = [ 9000 ] ++ lib.optionals consoleDirectlyReachable [ 9001 ];
  };
}
