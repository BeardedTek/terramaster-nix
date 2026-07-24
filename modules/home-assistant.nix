{ config, lib, pkgs, ... }:

let
  # HACS isn't packaged in pkgs.home-assistant-custom-components (it
  # self-updates at runtime by design, which doesn't fit Nix's reproducible
  # model) — fetch its release directly instead and drop it into place.
  # Final activation (linking a GitHub account) is a one-time interactive
  # step done through the HA UI itself, same shape as Frigate's
  # first-login flow.
  hacsVersion = "2.0.5";
  hacsSrc = pkgs.fetchzip {
    url = "https://github.com/hacs/integration/releases/download/${hacsVersion}/hacs.zip";
    sha256 = "0v7h2ma61wbshpm2p42lgmgq3pn6v4v29wz6rffqrv27ij52djl8";
    stripRoot = false; # the zip's contents are the component itself, no wrapping folder
  };
in
{
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "mqtt" # pairs with modules/mosquitto below
      "zwave_js" # pairs with services.zwave-js below (disabled until the dongle is attached)
    ];
    config = {
      http = {
        server_port = 8123;
        # Traefik proxies to 127.0.0.1:8123 — without these, HA rejects
        # every proxied request outright ("Requests from reverse proxies
        # will be blocked if these options are not set", per HA's own
        # http integration docs).
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" "::1" ];
      };
    };
  };

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

  # No USB Z-Wave dongle attached yet — serialPort has no sane default and
  # the service would just fail to start without a real device. Once it's
  # attached: `ls /dev/serial/by-id/` on the box for a stable path, then
  # set enable = true and serialPort to that path.
  services.zwave-js = {
    enable = false;
    serialPort = "/dev/ttyUSB0"; # placeholder, inert while disabled
  };

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        port = 1883;
        # Anonymous, network-scoped only (LAN + nebula1 firewall below) —
        # same trust posture as jellyfin/sonarr/etc. elsewhere in this
        # repo, not fronted by Traefik since MQTT isn't HTTP. Add per-user
        # credentials later if that's ever not sufficient.
        omitPasswordAuth = true;
        settings.listener_allow_anonymous = true;
      }
    ];
  };

  networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 1883 8123 ];
  networking.firewall.interfaces.${config.mySystem.lanInterface}.allowedTCPPorts = [ 1883 8123 ];

  # Routing (hass.young.beardedtek.com / hass-young.nebula.beardedtek.com)
  # comes from "hass" being listed in modules/traefik.nix's own `backends`
  # attrset directly — mySystem.serviceBackends flows one-way, *from*
  # traefik.nix *to* modules/dashboard.nix's status checks, not the other
  # way around. Setting it here instead of there would update the shared
  # option but silently create no actual Traefik router — confirmed the
  # hard way (port 8123 unreachable via any domain, since none actually
  # existed).
}
