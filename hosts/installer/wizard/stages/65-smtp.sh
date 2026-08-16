#!/usr/bin/env bash

# Not gated on a features-checklist flag — mySystem.smtp (modules/common.nix)
# is a standalone nullable option, not a mySystem.features.* toggle. Null
# means both the relay and any consumer's email notifications stay off
# (modules/authelia.nix falls back to local-file notifications), same as
# skipping this stage entirely.
stage_65_smtp() {
  if wiz_yesno "Outbound email" "Configure an outbound SMTP relay now? This lets Authelia and other services send email notifications (password resets, alerts). Skip to configure later from the dashboard's Preferences page."; then
    wiz_set have_smtp "true"
    wiz_set smtp_host "$(wiz_input "SMTP host" "Upstream SMTP relay hostname (e.g. smtp.mailgun.org).")"
    wiz_set smtp_port "$(wiz_input "SMTP port" "Upstream SMTP relay port." "587")"
    wiz_set smtp_scheme "$(wiz_menu "SMTP scheme" "Connection security:" \
      "submission" "STARTTLS on 587 (most common)" \
      "submissions" "Implicit TLS on 465" \
      "smtp" "Plaintext (not recommended)")"
    wiz_set smtp_sender "$(wiz_input "Sender address" "From: address for outgoing notifications (e.g. nas@example.com).")"
    wiz_set smtp_username "$(wiz_input "SMTP username" "Upstream relay account username.")"

    local pw pw2
    while true; do
      pw=$(wiz_password "SMTP password" "Upstream relay account password.")
      pw2=$(wiz_password "SMTP password" "Confirm:")
      [ "$pw" = "$pw2" ] && [ -n "$pw" ] && break
      wiz_msgbox "Mismatch" "Passwords didn't match or were empty — try again."
    done
    wiz_set smtp_password "$pw"
    unset pw pw2
  else
    wiz_set have_smtp "false"
  fi
}
