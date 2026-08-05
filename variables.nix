{
  networking.hostName = "young";

  mySystem.manufacturer = "terramaster";
  mySystem.model = "young";
  mySystem.domain = "beardedtek.com";

  # Fill in your real values here — the password is NOT set in this file,
  # it's delivered out-of-repo (see
  # secrets/extra-files/persist/etc/authelia/smtp_password.example and
  # docs/DEPLOYMENT.md's secrets table). Leave this whole block removed
  # (mySystem.smtp stays null) to keep Authelia's file-based notification
  # fallback instead.
  mySystem.smtp = {
    host = "mail.beardedtek.com";
    port = 465;
    scheme = "submission"; # "smtp", "submission", or "submissions"
    sender = "NO-REPLY@beardedtek.com";
    username = "no-reply@beardedtek.com";
  };

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

    # Phase 1 (LLDAP alone) validated on young. Phase 2: Authelia itself,
    # forward-auth gating exactly one low-stakes test service (Sonarr —
    # see modules/authelia.nix's candidateProtectedServices) to validate
    # the redirect round trip and the shared-session-across-both-domain-
    # shapes assumption before rolling out to the rest.
    sso.enable = true;
    sso.authelia.enable = true;

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
