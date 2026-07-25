{
  networking.hostName = "young";

  mySystem.manufacturer = "terramaster";
  mySystem.model = "young";

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
