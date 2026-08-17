#!/usr/bin/env bash

# Sole owner of Traefik/DNS-01 wizard state — absorbs what used to be a
# dead `have_traefik` USB-only check in 70-secrets.sh (set, never read
# anywhere). Not gated on a features-checklist flag: Traefik always runs
# (mySystem.features.traefikDns01.enable defaults to true, unconditionally),
# so this is offered unconditionally too, same posture as 65-smtp.sh.
#
# Runs AFTER stage_70_secrets, not between 66 and 70 — secrets_usb is
# only ever populated inside stage_70_secrets' own USB-mount detection;
# nothing else sets it, so this stage's USB check below would always see
# it empty if it ran any earlier.
stage_71_dns01() {
  if [ -n "$(wiz_get secrets_usb)" ] && [ -f "$(wiz_get secrets_usb)/etc/traefik/traefik.env" ]; then
    # 90-install.sh's blanket secrets_usb/etc/ copy already handles this.
    wiz_set have_traefik_dns01 "false"
    return 0
  fi

  wiz_set have_traefik_dns01 "false"
  if ! wiz_yesno "DNS-01 certificates" "Configure a real HTTPS certificate for this box now (DNS-01 via Let's Encrypt)? Needs network access and a domain whose DNS you control through one of ~15 supported providers. Skip to configure later from the dashboard's System Preferences page — until then, Traefik serves a placeholder cert that isn't trusted by anything."; then
    return 0
  fi

  local provider
  provider=$(wiz_menu "DNS provider" "Which provider hosts DNS for your domain?" \
    "linode" "Linode" \
    "cloudflare" "Cloudflare" \
    "digitalocean" "DigitalOcean" \
    "route53" "AWS Route 53" \
    "duckdns" "DuckDNS" \
    "godaddy" "GoDaddy" \
    "namecheap" "Namecheap" \
    "gcloud" "Google Cloud DNS (not supported here — see below)" \
    "azure" "Azure DNS" \
    "ovh" "OVH" \
    "porkbun" "Porkbun" \
    "vultr" "Vultr" \
    "hetzner" "Hetzner" \
    "gandi" "Gandi" \
    "desec" "deSEC")

  if [ "$provider" = "gcloud" ]; then
    wiz_msgbox "Not yet supported here" "Google Cloud DNS needs a multi-line service-account JSON key, which doesn't fit this wizard's text prompts. Skipping — configure it from the dashboard after first boot, or drop etc/traefik/traefik.env onto a NAS-SECRETS USB (see secrets/extra-files/persist/etc/traefik/traefik.env.example)."
    return 0
  fi

  local domain wildcard
  domain=$(wiz_input "Extra domain" "Domain for this cert (e.g. custom.example.com)." \
    "custom.$(wiz_get hostname).$(wiz_get domain)")
  wildcard=$(wiz_input "Extra wildcard" "Wildcard pattern for this cert." \
    "*.custom.$(wiz_get hostname).$(wiz_get domain)")
  case "$domain" in *[!a-zA-Z0-9.-]*) wiz_die "Invalid domain — only letters, digits, '.', '-' allowed." ;; esac
  case "$wildcard" in *[!a-zA-Z0-9.*-]*) wiz_die "Invalid wildcard — only letters, digits, '.', '*', '-' allowed." ;; esac

  # One field-name list per provider — hand-mirrored from
  # modules/traefik-dns01.nix's own providerFields (that file is the
  # source of truth for these exact names; update both if it ever
  # changes — the wizard can't read the .nix file at runtime).
  local fields=""
  case "$provider" in
    linode) fields="LINODE_TOKEN" ;;
    cloudflare) fields="CF_DNS_API_TOKEN" ;;
    digitalocean) fields="DO_AUTH_TOKEN" ;;
    route53) fields="AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY" ;;
    duckdns) fields="DUCKDNS_TOKEN" ;;
    godaddy) fields="GODADDY_API_KEY GODADDY_API_SECRET" ;;
    namecheap) fields="NAMECHEAP_API_USER NAMECHEAP_API_KEY" ;;
    azure) fields="AZURE_CLIENT_ID AZURE_CLIENT_SECRET AZURE_SUBSCRIPTION_ID AZURE_TENANT_ID AZURE_RESOURCE_GROUP" ;;
    ovh) fields="OVH_ENDPOINT OVH_APPLICATION_KEY OVH_APPLICATION_SECRET OVH_CONSUMER_KEY" ;;
    porkbun) fields="PORKBUN_API_KEY PORKBUN_SECRET_API_KEY" ;;
    vultr) fields="VULTR_API_KEY" ;;
    hetzner) fields="HETZNER_API_KEY" ;;
    gandi) fields="GANDI_BEARER_TOKEN" ;;
    desec) fields="DESEC_TOKEN" ;;
  esac

  # Builds the exact final traefik.env content here — 90-install.sh just
  # writes it verbatim, no provider knowledge needed there. Unquoted
  # KEY=VALUE per line, deliberately matching modules/traefik-dns01.nix's
  # own applyScript/write_env_line exactly (NOT the human-readable
  # single-quoted traefik.env.example) — systemd's EnvironmentFile=
  # doesn't strip quotes the way bash `source` does, so quoting this
  # would hand Traefik a literally-quoted, wrong value. Confirmed the
  # hard way with this exact class of mistake once already this session
  # (modules/minio.nix's own EnvironmentFile).
  local env_content
  env_content="TRAEFIK_DNS_PROVIDER=${provider}
TRAEFIK_EXTRA_DOMAIN=${domain}
TRAEFIK_EXTRA_WILDCARD=${wildcard}
"
  local field val
  for field in $fields; do
    val=$(wiz_password "$field" "Enter the value for $field (provider: $provider).")
    [ -n "$val" ] || wiz_die "$field can't be empty."
    env_content="${env_content}${field}=${val}
"
  done

  wiz_set have_traefik_dns01 "true"
  wiz_set traefik_env_content "$env_content"
}
