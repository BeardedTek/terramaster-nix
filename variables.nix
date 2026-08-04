{
  networking.hostName = "young";

  mySystem.manufacturer = "terramaster";
  mySystem.model = "young";
  mySystem.domain = "beardedtek.com";

  mySystem.users = [
    { name = "beardedtek"; wheel = true; }
    { name = "dyoung"; wheel = true; }
  ];

  mySystem.contactInfo = [
    {
      label = "Tech Support";
      email = "support@beardedtek.com";
      phone = "9075198577";
    }
    {
      label = "Sales";
      email = "sales@beardedtek.com";
      phone = "9075198577";
    }
    {
      label = "Customer Support";
      email = "help@beardedtek.com";
      phone = "9075198577";
    }
  ];

  mySystem.features = {
    jellyfin.enable = true;
    frigate.enable = true;
    minio.enable = true;
    filebrowser.enable = true;

    # Phase 1 of the SSO rollout: LLDAP alone, validated on its own
    # before Authelia (sso.authelia.enable) layers forward-auth on top
    # in Phase 2 — see the SSO plan. Nothing else changes yet: no
    # service is in mySystem.sso.protectedServices, so this just stands
    # the directory up and syncs mySystem.users into it.
    sso.enable = true;

    homeAssistant = {
      enable = true;
      zwave.enable = false;
      hacs.enable = true;
    };

    mediaAcquisition = {
      enable = true;
      seerr.enable = true;
      radarr.enable = true;
      sonarr.enable = true;
      jackett.enable = true;
      qbittorrent.enable = true;
    };
  };
}
