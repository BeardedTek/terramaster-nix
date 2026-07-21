{ pkgs, ... }:

{
  # The user already has a working config.yaml (with CA/cert/key embedded
  # inline in its `pki:` block, staged at
  # secrets/extra-files/etc/nebula/config.yaml, gitignored) — rather than
  # transcribing it into
  # the structured services.nebula.networks.<name> Nix options, run Nebula
  # as a plain systemd service against that file verbatim. It's delivered
  # to /etc/nebula/config.yaml via `nixos-anywhere --extra-files` (see
  # docs/DEPLOYMENT.md), never through the Nix store, so the embedded
  # private key stays out of a world-readable path.
  #
  # /etc/nebula is persisted via environment.persistence in
  # hosts/young/configuration.nix so it survives the tmpfs root.

  environment.systemPackages = [ pkgs.nebula ];

  systemd.services.nebula = {
    description = "Nebula overlay network";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.nebula}/bin/nebula -config /etc/nebula/config.yaml";
      Restart = "on-failure";
      RestartSec = "5s";
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
    };
  };
}
