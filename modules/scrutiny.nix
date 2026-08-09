{ config, lib, pkgs, ... }:

let
  f = config.mySystem.features;

  stampFile = "/var/lib/scrutiny-collector-state/.collected-once";

  # nixpkgs' own scrutiny-collector.timer only fires on its daily
  # schedule — Persistent=true only catches up on occurrences *missed*
  # while the system was off, it doesn't retroactively fire a timer
  # whose very first occurrence hasn't happened yet. Confirmed the hard
  # way: a freshly-enabled box showed an empty Scrutiny dashboard for
  # hours until the next midnight run. `systemctl start` (no --no-block)
  # blocks until scrutiny-collector.service itself finishes, so a
  # failure there fails this script too (via writeShellApplication's
  # own errexit) — the stamp file is deliberately only touched after
  # that succeeds, so a failed attempt correctly retries on next boot
  # instead of being marked done.
  bootstrapScript = pkgs.writeShellApplication {
    name = "scrutiny-collector-bootstrap";
    runtimeInputs = [ pkgs.systemd pkgs.coreutils ];
    text = ''
      systemctl start scrutiny-collector.service
      touch ${stampFile}
    '';
  };
in
{
  config = lib.mkIf f.scrutiny.enable {
    services.scrutiny = {
      enable = true;
      settings.web.listen.host = "127.0.0.1";
      # 8223 — next free port after Vaultwarden's 8222 in
      # modules/traefik.nix's backends table; Scrutiny's own default
      # (8080) collides with qBittorrent.
      settings.web.listen.port = 8223;
    };

    systemd.services.scrutiny-collector-bootstrap = {
      description = "Run the Scrutiny collector once on first boot if it has never collected before";
      after = [ "scrutiny.service" ];
      wants = [ "scrutiny.service" ];
      wantedBy = [ "multi-user.target" ];
      # "!" negates — only runs while the stamp is still absent.
      unitConfig.ConditionPathExists = "!${stampFile}";
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "scrutiny-collector-state";
        ExecStart = lib.getExe bootstrapScript;
        # Generous: the real collector run took ~35s for 4 drives in
        # testing; a box with many more disks needs headroom, and
        # nothing else waits on this unit synchronously.
        TimeoutStartSec = 300;
      };
    };
  };
}
