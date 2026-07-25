{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.features.homeAssistant;
  lanIf = config.mySystem.lanInterface;

  hacsVersion = "2.0.5";
  hacsSrc = pkgs.fetchzip {
    url = "https://github.com/hacs/integration/releases/download/${hacsVersion}/hacs.zip";
    sha256 = "0v7h2ma61wbshpm2p42lgmgq3pn6v4v29wz6rffqrv27ij52djl8";
    stripRoot = false;
  };
in
{
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.home-assistant = {
        enable = true;
        extraComponents = [ "mqtt" ] ++ lib.optionals cfg.zwave.enable [ "zwave_js" ];
        config.http = {
          server_port = 8123;
          use_x_forwarded_for = true;
          trusted_proxies = [ "127.0.0.1" "::1" ];
        };
      };

      services.zwave-js = {
        enable = cfg.zwave.enable;
        serialPort = "/dev/ttyUSB0";
      };

      services.mosquitto = {
        enable = true;
        listeners = [
          {
            port = 1883;
            omitPasswordAuth = true;
            settings.listener_allow_anonymous = true;
          }
        ];
      };

      networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 1883 8123 ];
      networking.firewall.interfaces.${lanIf}.allowedTCPPorts = [ 1883 8123 ];
    }

    (lib.mkIf cfg.hacs.enable {
      systemd.services.hass-install-hacs = {
        description = "Install/update the HACS custom component for Home Assistant";
        serviceConfig = {
          Type = "oneshot";
          User = "hass";
          Group = "hass";
        };
        script = ''
          mkdir -p /var/lib/hass/custom_components
          rm -rf /var/lib/hass/custom_components/hacs
          cp -r ${hacsSrc} /var/lib/hass/custom_components/hacs
          chmod -R u+w /var/lib/hass/custom_components/hacs
        '';
      };
      systemd.services.home-assistant = {
        after = [ "hass-install-hacs.service" ];
        requires = [ "hass-install-hacs.service" ];
      };
    })
  ]);
}
