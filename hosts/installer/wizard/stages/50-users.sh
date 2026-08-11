#!/usr/bin/env bash

# Hashes are computed locally, right here, with mkpasswd -m sha-512 (same
# tool docs/DEPLOYMENT.md already documents) — plaintext never touches
# disk and isn't stored in $WIZ past this function returning.
stage_50_users() {
  local root_pw
  while true; do
    root_pw=$(wiz_password "Root password" "Set a password for root (used only if you ever need local recovery access — normal login is via the users you add next).")
    local root_pw2
    root_pw2=$(wiz_password "Root password" "Confirm the root password:")
    [ "$root_pw" = "$root_pw2" ] && [ -n "$root_pw" ] && break
    wiz_msgbox "Mismatch" "Passwords didn't match or were empty — try again."
  done
  wiz_set root_hash "$(mkpasswd -m sha-512 "$root_pw")"
  unset root_pw root_pw2

  local user_list=""
  local have_wheel=false

  while true; do
    local name
    name=$(wiz_input "Add a user" "Username (lowercase, no spaces). Leave blank to finish adding users.")
    [ -z "$name" ] && break
    if ! [[ "$name" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
      wiz_msgbox "Invalid name" "\"$name\" isn't a valid Linux username. Try again."
      continue
    fi

    local wheel="false"
    wiz_yesno "$name: sudo access?" "Should $name be able to sudo (member of wheel)?" && wheel="true"
    [ "$wheel" = "true" ] && have_wheel=true

    local pw pw2
    while true; do
      pw=$(wiz_password "$name's password" "Set $name's initial password:")
      pw2=$(wiz_password "$name's password" "Confirm $name's password:")
      [ "$pw" = "$pw2" ] && [ -n "$pw" ] && break
      wiz_msgbox "Mismatch" "Passwords didn't match or were empty — try again."
    done
    wiz_set "hash_${name}" "$(mkpasswd -m sha-512 "$pw")"
    # Retained a little longer than the hash alone would require — SSO
    # isn't known yet at this point in the stage order (60-features
    # runs after this one), so this is kept around in case stage 90
    # needs to seed the same password into LLDAP. Same in-process-only
    # $WIZ trust boundary ldap_admin_password (stage 70) already uses;
    # consumed and wiz_unset by stage 90 if SSO is on, or just vanishes
    # with the process if it isn't.
    wiz_set "plainpw_${name}" "$pw"
    unset pw pw2

    wiz_set "wheel_${name}" "$wheel"
    user_list="${user_list}${name}
"
  done

  if [ -z "$user_list" ]; then
    wiz_die "At least one user is required."
  fi
  if [ "$have_wheel" = false ]; then
    wiz_yesno "No admin user" "None of the users you added have sudo access. Continue anyway?" \
      || { wiz_msgbox "Add a user" "Add at least one user with sudo access."; stage_50_users; return; }
  fi

  wiz_set user_list "$user_list"
}
