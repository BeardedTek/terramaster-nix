{ config, lib, ... }:

let
  smtp = config.mySystem.smtp;

  # mySystem.smtp.scheme uses Authelia's own vocabulary (smtp/submission/
  # submissions — genuine IANA service names, not Authelia-specific) since
  # that's the option's original consumer; OpenSMTPD's relay URL scheme
  # names differ, so translate rather than rename the shared option.
  opensmtpdScheme = {
    smtp = "smtp";
    submission = "smtp+tls";
    submissions = "smtps";
  }.${smtp.scheme};
in
{
  config = lib.mkIf (smtp != null) {
    # Loopback-only relay every local service can hand mail to
    # unauthenticated — the real upstream provider's credentials live
    # here, in exactly one place, instead of being plumbed through every
    # consumer (modules/authelia.nix, and whatever else wants to send
    # mail later) individually. Nothing to open in the firewall: `listen
    # on lo` never touches a real network interface, so there's no
    # binding to accidentally expose, unlike services that listen
    # broadly and rely on firewall rules to stay local.
    services.opensmtpd = {
      enable = true;
      serverConfiguration = ''
        table secrets file:/etc/opensmtpd/secrets

        listen on lo

        action "relay_out" relay host ${opensmtpdScheme}://relay@${smtp.host}:${toString smtp.port} auth <secrets>

        match from local for any action "relay_out"
      '';
    };
  };
}
