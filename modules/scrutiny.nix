{ config, lib, ... }:

let
  f = config.mySystem.features;
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
  };
}
