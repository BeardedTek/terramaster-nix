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

  mySystem.users = [
${users_nix}  ];

  mySystem.contactInfo = [ ];

  mySystem.security.sshPasswordAuth = $(wiz_get use_password_auth);

  mySystem.features = {
    jellyfin.enable = $(f jellyfin);
    frigate.enable = $(f frigate);
    minio.enable = $(f minio);
    filebrowser.enable = $(f filebrowser);

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
      "/var/lib/sonarr"
      "/var/lib/radarr"
      "/var/lib/jackett"
      "/var/lib/seerr"
      "/var/lib/qBittorrent"
      "/var/lib/traefik"
      "/var/lib/frigate"
      "/var/lib/hass"
      "/var/lib/mosquitto"
      "/etc/minio"
      "/var/lib/filebrowser"
      "/etc/filebrowser"
      "/etc/nas-update"
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
  cat <<EOF
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
