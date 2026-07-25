#!/usr/bin/env bash

# Mirrors mySystem.features' exact shape (modules/common.nix) so
# 90-install.sh can write variables.nix straight from these flags.
stage_60_features() {
  local selected
  selected=$(wiz_checklist "Services" \
    "Pick every service to enable. Home Assistant/Media Acquisition are group toggles — their sub-items only matter if the group itself is checked." \
    "jellyfin"            "Jellyfin (media server)"                    "ON" \
    "frigate"             "Frigate (NVR)"                              "ON" \
    "homeassistant"       "Home Assistant + Mosquitto + Samba share"   "ON" \
    "homeassistant_hacs"  "  -> HACS"                                  "ON" \
    "homeassistant_zwave" "  -> Z-Wave JS (only if a dongle is attached)" "OFF" \
    "mediaacq"            "Media acquisition group"                    "ON" \
    "mediaacq_seerr"      "  -> Seerr"                                 "ON" \
    "mediaacq_radarr"     "  -> Radarr"                                "ON" \
    "mediaacq_sonarr"     "  -> Sonarr"                                "ON" \
    "mediaacq_jackett"    "  -> Jackett"                               "ON" \
    "mediaacq_qbittorrent" "  -> qBittorrent"                          "ON"
  )

  local flag
  for flag in jellyfin frigate homeassistant homeassistant_hacs homeassistant_zwave \
              mediaacq mediaacq_seerr mediaacq_radarr mediaacq_sonarr mediaacq_jackett mediaacq_qbittorrent; do
    if [[ " $selected " == *"\"$flag\""* ]]; then
      wiz_set "feature_$flag" "true"
    else
      wiz_set "feature_$flag" "false"
    fi
  done
}
