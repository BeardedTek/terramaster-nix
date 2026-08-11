#!/usr/bin/env bash
# One scripted "everything on" run: new pool across 4 blank disks
# (matching the terramaster-nix-installer VM's real topology), every
# feature flag enabled — the case most likely to hit a missing-option
# eval bug like mySystem.domain, since it touches the most modules.

# lib/pool-new.sh's dry-run fixtures — no real block devices needed.
export WIZ_DRY_RUN=1
export WIZ_DRY_RUN_DISKS=$'boot-disk\npool-disk0\npool-disk1\npool-disk2\npool-disk3'
export WIZ_DRY_RUN_SIZE_BYTES=6001175126016
export WIZ_DRY_RUN_DIRTY_DISKS=""
export WIZ_DRY_RUN_SELF_BOOT_KNAME=""

MOCK_YESNO["Check for updates?"]="false"
MOCK_ANSWERS["LAN interface"]="eth0"

MOCK_ANSWERS["Manufacturer"]="terramaster"
MOCK_ANSWERS["Instance name"]="wiztest"
MOCK_ANSWERS["Hostname"]="wiztest"
MOCK_ANSWERS["Domain"]="test.invalid"
MOCK_ANSWERS["ZFS hostid"]="deadbeef"

MOCK_ANSWERS["Storage"]="new"
MOCK_ANSWERS["Boot drive"]="boot-disk"
MOCK_ANSWERS["Pool disks"]='"pool-disk0" "pool-disk1" "pool-disk2" "pool-disk3"'
MOCK_ANSWERS["RAID level"]="raidz1"
MOCK_ANSWERS["Pool name"]="rust"

MOCK_ANSWERS["Root password"]="TestRootPass123!"
MOCK_ANSWER_QUEUES["Add a user"]=$'testadmin\ntestuser2\n'
MOCK_YESNO["testadmin: sudo access?"]="true"
MOCK_ANSWERS["testadmin's password"]="TestAdminPass123!"
MOCK_YESNO["testuser2: sudo access?"]="false"
MOCK_ANSWERS["testuser2's password"]="TestUser2Pass123!"

# homeassistant_zwave deliberately left unchecked: enabling it requires
# a real serial device path hand-edited into modules/home-assistant.nix
# afterward (services.zwave-js.secretsConfigFile has no default) — not
# something the wizard alone can produce a working config for, matching
# its own real default (OFF, "no dongle attached yet") and the
# Architecture doc's documented manual Z-Wave enablement steps.
MOCK_ANSWERS["Services"]='"sso" "sso_authelia" "jellyfin" "frigate" "minio" "filebrowser" "homeassistant" "homeassistant_hacs" "mediaacq" "mediaacq_seerr" "mediaacq_radarr" "mediaacq_sonarr" "mediaacq_jackett" "mediaacq_qbittorrent" "immich" "nebula"'

MOCK_ANSWERS["SSH access for testadmin"]="password"
MOCK_YESNO["Use password login?"]="true"
MOCK_ANSWERS["LLDAP admin password"]="TestLdapAdmin123!"
MOCK_YESNO["Nebula"]="false"

MOCK_ANSWERS["Confirm"]="DESTROY"
