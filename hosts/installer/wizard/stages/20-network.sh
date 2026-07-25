#!/usr/bin/env bash

stage_20_network() {
  local candidates=()
  local iface
  while IFS= read -r iface; do
    case "$iface" in
      lo|nebula*|veth*|docker*|virbr*|br-*) ;;
      *) candidates+=("$iface") ;;
    esac
  done < <(ip -o link show | awk -F': ' '{print $2}')

  if [ "${#candidates[@]}" -eq 0 ]; then
    wiz_die "No candidate network interfaces found (ip -o link show returned nothing usable). Check the NAS is cabled up and try again."
  fi

  local menu_items=()
  for iface in "${candidates[@]}"; do
    local addr
    addr=$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | head -n1)
    menu_items+=("$iface" "${addr:-no IPv4 address yet}")
  done

  local chosen
  chosen=$(wiz_menu "LAN interface" "Which interface is this NAS's LAN connection?" "${menu_items[@]}")
  wiz_set lan_if "$chosen"

  local addr
  addr=$(ip -4 -o addr show dev "$chosen" 2>/dev/null | awk '{print $4}' | head -n1)
  if [ -z "$addr" ]; then
    wiz_msgbox "No IP address yet" "$chosen has no IPv4 address. This is fine if DHCP hasn't assigned one yet, but SSH access to this wizard won't work until it does. Continuing on the local console."
  fi
}
