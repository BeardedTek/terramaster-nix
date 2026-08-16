#!/usr/bin/env bash
# Renders the wizard's collected $WIZ state into real repo files. Pure
# string generation — no side effects, easy to unit-test against a
# hand-populated $WIZ array.

gen_variables_nix() {
  local users_nix=""
  local name
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    local wheel
    wheel=$(wiz_get "wheel_${name}")
    users_nix+="    { name = \"${name}\"; wheel = ${wheel}; }
"
  done <<< "$(wiz_get user_list)"

  f() { wiz_get "feature_$1"; }

  cat <<EOF
{
  networking.hostName = "$(wiz_get hostname)";

  mySystem.manufacturer = "$(wiz_get manufacturer)";
  mySystem.model = "$(wiz_get instance)";
  mySystem.domain = "$(wiz_get domain)";

  mySystem.users = [
${users_nix}  ];

  mySystem.contactInfo = [ ];

  mySystem.lanInterface = "$(wiz_get lan_if)";

  mySystem.security.sshPasswordAuth = $(wiz_get use_password_auth);

  mySystem.smtp = $(if [ "$(wiz_get have_smtp)" = "true" ]; then cat <<SMTPEOF
{
    host = "$(wiz_get smtp_host)";
    port = $(wiz_get smtp_port);
    scheme = "$(wiz_get smtp_scheme)";
    sender = "$(wiz_get smtp_sender)";
    username = "$(wiz_get smtp_username)";
  }
SMTPEOF
else printf null; fi);

  mySystem.features = {
    jellyfin.enable = $(f jellyfin);
    plex.enable = $(f plex);
    frigate.enable = $(f frigate);
    minio.enable = $(f minio);
    filebrowser.enable = $(f filebrowser);
    immich.enable = $(f immich);
    nebula.enable = $(f nebula);
    tailscale.enable = $(f tailscale);
    vaultwarden.enable = $(f vaultwarden);
    scrutiny.enable = $(f scrutiny);

    sso.enable = $(f sso);
    sso.authelia.enable = $(f sso_authelia);

    homeAssistant = {
      enable = $(f homeassistant);
      zwave.enable = $(f homeassistant_zwave);
      hacs.enable = $(f homeassistant_hacs);
    };

    mediaAcquisition = {
      enable = $(f mediaacq);
      seerr.enable = $(f mediaacq_seerr);
      radarr.enable = $(f mediaacq_radarr);
      sonarr.enable = $(f mediaacq_sonarr);
      jackett.enable = $(f mediaacq_jackett);
      qbittorrent.enable = $(f mediaacq_qbittorrent);
    };
  };
}
EOF
}

# Same directories/files list hosts/terramaster/young and .../f4-245 both
# already use — service state dirs are driven by mySystem.features, not
# by the storage layout, so this list doesn't vary between the two paths.
_gen_persistence_block() {
  cat <<'EOF'
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/etc/nebula"
      "/etc/traefik"
      "/var/lib/samba"
      "/var/lib/jellyfin"
      { directory = "/var/lib/plex"; user = "plex"; group = "plex"; mode = "0755"; }
      "/var/lib/sonarr"
      "/var/lib/radarr"
      "/var/lib/jackett"
      "/var/lib/seerr"
      "/var/lib/qBittorrent"
      "/var/lib/traefik"
      "/var/lib/frigate"
      { directory = "/var/lib/hass"; user = "hass"; group = "hass"; mode = "0755"; }
      { directory = "/var/lib/mosquitto"; user = "mosquitto"; group = "mosquitto"; mode = "0755"; }
      "/etc/minio"
      "/var/lib/filebrowser"
      "/etc/filebrowser"
      "/etc/lldap"
      "/etc/authelia"
      "/var/lib/authelia-main"
      "/etc/opensmtpd"
      "/etc/jellyfin"
      "/etc/dashboard-login"
      "/etc/unix-ldap-login"
      "/etc/vaultwarden"
      "/var/lib/vaultwarden"
      "/etc/tailscale"
      "/var/lib/tailscale"
      "/var/lib/influxdb2"
      "/var/lib/scrutiny-collector-state"
      { directory = "/var/lib/private"; user = "root"; group = "root"; mode = "0700"; }
      { directory = "/var/lib/postgresql"; user = "postgres"; group = "postgres"; mode = "0700"; }
      "/var/lib/immich"
      "/var/cache/immich"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
EOF
}

# Runtime dataset-creation safety net for the optional, feature-gated
# /<pool>/minio and /<pool>/immich datasets — same lib.mkIf-gated
# fileSystems + zfs-ensure-<name>-dataset oneshot pattern as
# hosts/terramaster/young/configuration.nix (ported here after that
# exact gap — an unconditionally-mounted dataset that didn't exist yet
# — caused a real production boot failure there). Only ever creates,
# never destroys. Needed by both storage paths: neither disko (new
# pool) nor an adopted pool (existing) know about these two optional
# per-feature datasets ahead of time, so this stays a purely runtime,
# post-mount concern rather than something baked into pool creation.
# `${pool}.mount` exists as a real unit for both paths — the existing-
# pool generator declares fileSystems."/${pool}" directly below, and
# lib/zfs-pool.nix sets the new-pool disko zpool's own mountpoint to
# "/${poolName}", so disko produces the same top-level mount.
_gen_zfs_ensure_block() {
  local pool="$1" name="$2"
  cat <<EOF
  fileSystems."/${pool}/${name}" = lib.mkIf f.${name}.enable {
    device = "${pool}/${name}";
    fsType = "zfs";
  };
  systemd.services."zfs-ensure-${name}-dataset" = lib.mkIf f.${name}.enable {
    description = "Ensure the ${pool}/${name} ZFS dataset exists before mounting it";
    # DefaultDependencies = false is required, not cosmetic: without it
    # this oneshot picks up systemd's normal After=basic.target, which
    # pulls in sockets.target -> every enabled .socket unit (e.g.
    # fcgiwrap-dashboard-nebula.socket) -> sysinit.target ->
    # systemd-update-done.service -> local-fs.target — closing a real
    # ordering cycle back to "${pool}-${name}.mount", since that mount
    # unit's own Before=local-fs.target makes local-fs.target implicitly
    # After= it. Confirmed the hard way in a real Tier 2 VM boot:
    # systemd silently breaks the cycle by deleting
    # "${pool}-${name}.mount"'s own start job, so the ensure-service
    # still runs and creates the dataset, but the mount itself never
    # happens and the dependent service (e.g. minio.service) just sits
    # inactive with no error surfaced anywhere obvious. Early-boot-only
    # oneshots that must run before a specific local mount need this,
    # same as systemd-fsck@ and other early mount helpers.
    unitConfig.DefaultDependencies = false;
    after = [ "${pool}.mount" ];
    requires = [ "${pool}.mount" ];
    before = [ "${pool}-${name}.mount" "local-fs.target" ];
    requiredBy = [ "${pool}-${name}.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if ! \${config.boot.zfs.package}/bin/zfs list "${pool}/${name}" >/dev/null 2>&1; then
        \${config.boot.zfs.package}/bin/zfs create "${pool}/${name}"
      fi
    '';
  };
EOF
}

# Path A: hand-written fileSystems, same shape as
# hosts/terramaster/young/configuration.nix — the pool is never
# disko-managed here, so nothing derives these automatically.
gen_configuration_nix_existing() {
  local pool home media data
  pool=$(wiz_get pool_name)
  home=$(wiz_get role_home)
  media=$(wiz_get role_media)
  data=$(wiz_get role_data)

  cat <<EOF
{ config, lib, ... }:
let
  f = config.mySystem.features;
in
{
  system.stateVersion = "26.05";

  networking.hostId = "$(wiz_get hostid)";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "size=2G" "mode=755" ];
  };

  fileSystems."/nix" = {
    device = "${pool}/nix";
    fsType = "zfs";
    neededForBoot = true;
  };
  fileSystems."/persist" = {
    device = "${pool}/persist";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/${pool}" = {
    device = "${pool}";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "${home}";
    fsType = "zfs";
  };
  fileSystems."/${pool}/media" = {
    device = "${media}";
    fsType = "zfs";
  };
  fileSystems."/${pool}/data" = {
    device = "${data}";
    fsType = "zfs";
  };

$(_gen_zfs_ensure_block "$pool" "minio")
$(_gen_zfs_ensure_block "$pool" "immich")

$(_gen_persistence_block)
}
EOF
}

# Path B: disko already derives fileSystems for everything the pool
# covers (see hosts/terramaster/f4-245/configuration.nix, the template
# this mirrors) — nothing to hand-write beyond hostId, the tmpfs root,
# and neededForBoot on /nix and /persist. disko has no way to know those
# two specifically need to be mounted before stage-2 activation (that's
# an application-level fact, not something derivable from the pool
# layout) — confirmed the hard way: impermanence's own assertion
# ("filesystems used for persistent storage must have neededForBoot
# set") failed on a real install using this generator before this was
# added, since disko's auto-generated fileSystems entries default it to
# false.
gen_configuration_nix_new() {
  local pool
  pool=$(wiz_get pool_name)

  cat <<EOF
{ config, lib, ... }:
let
  f = config.mySystem.features;
in
{
  system.stateVersion = "26.05";

  networking.hostId = "$(wiz_get hostid)";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "size=2G" "mode=755" ];
  };

  fileSystems."/nix".neededForBoot = true;
  fileSystems."/persist".neededForBoot = true;

$(_gen_zfs_ensure_block "$pool" "minio")
$(_gen_zfs_ensure_block "$pool" "immich")

$(_gen_persistence_block)
}
EOF
}

gen_initial_passwords_env() {
  echo "ROOT_INITIAL_HASH='$(wiz_get root_hash)'"
  local name
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    echo "$(echo "$name" | tr '[:lower:]' '[:upper:]')_INITIAL_HASH='$(wiz_get "hash_${name}")'"
  done <<< "$(wiz_get user_list)"
}
