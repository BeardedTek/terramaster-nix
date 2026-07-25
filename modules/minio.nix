{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.minio;
  lanIf = config.mySystem.lanInterface;
in
{
  config = lib.mkIf cfg.enable {
    services.minio = {
      enable = true;
      package = pkgs.callPackage ../pkgs/minio.nix { };
      listenAddress = ":9000";
      consoleAddress = ":9001";
      # Root credentials are out-of-repo, same pattern as Traefik's
      # LINODE_TOKEN — see secrets/extra-files/persist/etc/minio/minio.env.example
      # and docs/DEPLOYMENT.md's secrets table. Missing the file is a
      # clean no-start (services.minio sets ConditionPathExists on it),
      # not a crash loop.
      rootCredentialsFile = "/etc/minio/minio.env";
    };

    networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 9000 9001 ];
    networking.firewall.interfaces.${lanIf}.allowedTCPPorts = [ 9000 9001 ];
  };
}
