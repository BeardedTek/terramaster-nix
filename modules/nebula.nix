{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.mySystem.features.nebula.enable {
    environment.systemPackages = [ pkgs.nebula ];

    systemd.services.nebula = {
      description = "Nebula overlay network";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      # nebula.enable defaulting to true with no config uploaded yet is a
      # normal, expected transient state now that modules/dashboard-nebula.nix
      # lets an admin flip this on and paste a config moments later —
      # ConditionPathExists turns that window into a clean "inactive
      # (condition failed)" instead of a Restart=on-failure crash loop.
      unitConfig.ConditionPathExists = "/etc/nebula/config.yaml";
      serviceConfig = {
        ExecStart = "${pkgs.nebula}/bin/nebula -config /etc/nebula/config.yaml";
        Restart = "on-failure";
        RestartSec = "5s";
        AmbientCapabilities = [ "CAP_NET_ADMIN" ];
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
      };
    };
  };
}
