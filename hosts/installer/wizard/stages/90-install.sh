#!/usr/bin/env bash

stage_90_install() {
  local manufacturer instance host_dir
  manufacturer=$(wiz_get manufacturer)
  instance=$(wiz_get instance)
  host_dir="$WIZ_REPO_WORKDIR/hosts/$manufacturer/$instance"
  mkdir -p "$host_dir"

  # flake.nix reads each host's (gitignored, never-committed) variables.nix
  # through a real absolute filesystem path, built from $PWD, whenever the
  # ordinary self-relative path isn't visible (see its own repoRoot
  # comment) — which happens whenever $WIZ_REPO_WORKDIR is an actual git
  # checkout (stage_10_repo_update's "check for updates" -> real `git
  # clone` path) rather than the baked-in ISO snapshot (no .git at all,
  # so nothing's filtered and this fallback is never needed there).
  # run.sh is launched from whatever directory the console's login shell
  # started in — never $WIZ_REPO_WORKDIR itself — so without this, that
  # $PWD-based fallback would silently point at the wrong place the one
  # time it's actually needed. Every flake-evaluating command below
  # (disko, nixos-install) needs $PWD to genuinely be $WIZ_REPO_WORKDIR,
  # not just the "$WIZ_REPO_WORKDIR#..." flake ref they already pass.
  cd "$WIZ_REPO_WORKDIR"

  # Below, every flake ref built from $WIZ_REPO_WORKDIR is prefixed
  # "path:" — forces Nix to read it as a plain directory rather than
  # auto-detecting the "check for updates" git clone as a real git repo
  # and evaluating strictly against its last COMMITTED revision. Without
  # this, a brand-new instance name (this stage's own variables.nix/
  # configuration.nix/disko.nix, just written above — never `git add`ed)
  # is invisible to that evaluation: not merely "variables.nix missing"
  # (which the repoRoot fallback above already covers), but the entire
  # hosts/<manufacturer>/<instance>/ directory doesn't exist in the git
  # tree at all, so it's never even discovered as a candidate host —
  # flake.nix's own instanceNames enumeration (builtins.readDir on the
  # git-relative manufacturer directory) simply can't see an untracked
  # directory. Confirmed the hard way on a real install: nixos-install
  # failed with "does not provide attribute ...nixosConfigurations.
  # '<instance>'..." — not an eval error inside the host, a complete
  # absence of it from the flake's outputs. The baked-in-snapshot path
  # (no .git at all) was never affected, which is exactly why this
  # wasn't caught earlier — every existing automated test happened to
  # answer "no" to "check for updates?".
  local path_prefix="path:"

  wiz_msgbox "Writing config" "Generating variables.nix, configuration.nix, and secrets into $WIZ_REPO_WORKDIR now."

  # variables.nix lives inside host_dir (not $WIZ_REPO_WORKDIR's top
  # level) — flake.nix discovers every hosts/<manufacturer>/<instance>/
  # directory that has its own variables.nix, so multiple real machines'
  # configs coexist in one checkout with no top-level file to clobber
  # between hosts.
  gen_variables_nix > "$host_dir/variables.nix"
  if [ "$(wiz_get storage_path)" = "existing" ]; then
    gen_configuration_nix_existing > "$host_dir/configuration.nix"
  else
    gen_configuration_nix_new > "$host_dir/configuration.nix"
  fi
  mkdir -p "$WIZ_REPO_WORKDIR/secrets"
  gen_initial_passwords_env > "$WIZ_REPO_WORKDIR/secrets/initial-passwords.env"
  chmod 600 "$WIZ_REPO_WORKDIR/secrets/initial-passwords.env"

  # disko.nix was already written by the storage stage (40-storage-existing.sh
  # or 40-storage-new.sh) — it's the one file generated before this point,
  # since 40-storage-new.sh needs to show it for review before the
  # destructive confirmation.

  set -a
  # shellcheck disable=SC1091
  source "$WIZ_REPO_WORKDIR/secrets/initial-passwords.env"
  set +a
  export NIX_CONFIG="pure-eval = false"

  local flake_attr
  flake_attr="${path_prefix}$WIZ_REPO_WORKDIR#$(wiz_get hostname)"

  if [ "$(wiz_get storage_path)" = "new" ]; then
    wiz_msgbox "Running disko" "About to format and mount every disk selected earlier. This is the point of no return."
    # Stamp the live session's hostid to match the target BEFORE disko
    # creates the pool — otherwise `zpool create` stamps it with this
    # live ISO's own hostid (hardcoded "00000000"), and the target
    # system's first real boot fails to auto-import it (hostid
    # mismatch, same class of problem docs/DEPLOYMENT.md step 3 already
    # solves for the existing-pool path — confirmed the hard way that
    # the new-pool path needed the exact same fix, just applied earlier,
    # before creation instead of before import).
    wiz_set_hostid "$(wiz_get hostid)"
    pool_new_run_disko "${path_prefix}$WIZ_REPO_WORKDIR" "$(wiz_get hostname)"
  else
    # Boot drive only — disko doesn't know about the adopted pool.
    disko --mode destroy,format,mount --flake "$flake_attr"

    local pool home media data
    pool=$(wiz_get pool_name)
    home=$(wiz_get role_home)
    media=$(wiz_get role_media)
    data=$(wiz_get role_data)

    mkdir -p "/mnt/nix" "/mnt/persist" "/mnt/home" "/mnt/$pool"
    mount -t zfs "$pool/nix" /mnt/nix
    mount -t zfs "$pool/persist" /mnt/persist
    mount -t zfs "$home" /mnt/home
    mount -t zfs "$pool" "/mnt/$pool"
    mkdir -p "/mnt/$pool/media" "/mnt/$pool/data"
    mount -t zfs "$media" "/mnt/$pool/media"
    mount -t zfs "$data" "/mnt/$pool/data"
  fi

  # modules/filebrowser.nix and modules/frigate.nix both read a secret via
  # builtins.readFile "/persist/etc/..." — an *eval-time* read (not a
  # runtime *File option), which nixos-install's own `nix build`-under-
  # the-hood resolves against this live installer's ambient root, NOT
  # --root /mnt. On a fresh install /mnt/persist is the only place that
  # data exists (nothing is mounted at bare /persist yet — this session
  # booted off a tmpfs root), so those reads always fail with "path
  # '/persist/etc/...' does not exist" unless something makes the two
  # agree. Bind-mounting closes that gap for every secret written under
  # /mnt/persist below, present and future, without each module needing
  # its own special case.
  mkdir -p /persist
  mount --bind /mnt/persist /persist

  # modules/system-rebuild.nix (self-update and dashboard-svcconfig's own
  # rebuild trigger) needs this persisted here permanently, not just in
  # $WIZ_REPO_WORKDIR — it downloads a fresh release tarball from GitHub
  # on every single update and rebuilds directly against that, so the
  # workstation-only secrets/initial-passwords.env would otherwise never
  # exist anywhere in that freshly-downloaded tree. (variables.nix has
  # the same problem, since it's gitignored — but that's already solved
  # below, where $host_dir gets copied to nixos-installer-output/
  # $instance/; modules/system-rebuild.nix reads its own copy straight
  # from there, no separate copy needed here.) Confirmed the hard way:
  # without this, self-update fails outright the first time it's ever
  # used, with no indication anywhere in the install flow that anything
  # was missing.
  mkdir -p /mnt/persist/secrets
  cp "$WIZ_REPO_WORKDIR/secrets/initial-passwords.env" /mnt/persist/secrets/initial-passwords.env
  chmod 600 /mnt/persist/secrets/initial-passwords.env

  local first_user
  first_user=$(wiz_get user_list | head -n1)
  if [ -n "$(wiz_get ssh_pubkey)" ]; then
    mkdir -p "/mnt/home/$first_user/.ssh"
    wiz_get ssh_pubkey > "/mnt/home/$first_user/.ssh/authorized_keys"
    chmod 700 "/mnt/home/$first_user/.ssh"
    chmod 600 "/mnt/home/$first_user/.ssh/authorized_keys"
  fi

  # /mnt/persist, not /mnt/etc: only /mnt/persist (and /mnt/nix, /mnt/home,
  # the pool paths) are real mounted filesystems at install time — /mnt/etc
  # is ephemeral install-scratch space that's gone once the installed
  # system boots into its tmpfs root. Writing here instead of /mnt/etc
  # confirmed the hard way for Nebula's config in the nixos-anywhere path
  # (see docs/content/en/docs/architecture/_index.md's Failure modes
  # section) — same fix applies here.
  local secrets_usb
  secrets_usb=$(wiz_get secrets_usb)
  if [ -n "$secrets_usb" ] && [ -d "$secrets_usb/etc" ]; then
    mkdir -p /mnt/persist/etc
    cp -r "$secrets_usb/etc/." /mnt/persist/etc/
  fi

  # MinIO root credentials — same "generate one automatically unless
  # something already provided a real file" treatment as FileBrowser's
  # own admin.env below, so a no-secrets-USB install ends up with a
  # working MinIO instead of one that silently never starts (services.
  # minio's ConditionPathExists on this exact file — see modules/
  # minio.nix's rootCredentialsFile comment). Checked after the
  # secrets_usb copy above, so a USB-provided etc/minio/minio.env is
  # always left untouched. Deliberately does NOT print the generated
  # password anywhere in this wizard's own output — same posture as
  # FileBrowser's admin.env below: retrieve it from the file itself, or
  # rotate it from the dashboard's Service Configuration page, after boot.
  if [ "$(wiz_get feature_minio)" = "true" ] && [ ! -f /mnt/persist/etc/minio/minio.env ]; then
    mkdir -p /mnt/persist/etc/minio
    {
      echo "MINIO_ROOT_USER=minioadmin"
      echo "MINIO_ROOT_PASSWORD=$(openssl rand -hex 16)"
    } > /mnt/persist/etc/minio/minio.env
    chmod 600 /mnt/persist/etc/minio/minio.env
  fi

  # OpenSMTPd relay credentials — same table(5) format
  # secrets/extra-files/persist/etc/opensmtpd/secrets.example documents.
  # modules/smtp-relay.nix reads this at runtime (services.opensmtpd's own
  # secrets file), not at eval time, so this is just a plain file write,
  # no argon2/openssl involved.
  if [ "$(wiz_get have_smtp)" = "true" ]; then
    mkdir -p /mnt/persist/etc/opensmtpd
    printf 'relay %s:%s\n' "$(wiz_get smtp_username)" "$(wiz_get smtp_password)" > /mnt/persist/etc/opensmtpd/secrets
    chmod 600 /mnt/persist/etc/opensmtpd/secrets
  fi

  # Tailscale — either a pasted reusable auth key (modules/tailscale.nix's
  # authKeyFile) or, for the live-login flow, this installer session's own
  # now-authenticated tailscaled state copied straight onto the target so
  # it resumes the same node identity on first real boot. Neither branch
  # runs anything if the wizard's own stage was skipped/declined — no
  # authkey file at all is the same "clean no-op" modules/dashboard-
  # tailscale.nix's defaultsScript already handles on first real boot.
  case "$(wiz_get have_tailscale)" in
    authkey)
      mkdir -p /mnt/persist/etc/tailscale
      printf '%s' "$(wiz_get tailscale_authkey)" > /mnt/persist/etc/tailscale/authkey
      chmod 600 /mnt/persist/etc/tailscale/authkey
      ;;
    live)
      systemctl stop tailscaled 2>/dev/null || true
      mkdir -p /mnt/persist/var/lib/tailscale
      cp -a /var/lib/tailscale/. /mnt/persist/var/lib/tailscale/
      ;;
  esac

  # Traefik DNS-01 — stage_71_dns01 already built the exact final
  # traefik.env content (unquoted KEY=VALUE lines, matching modules/
  # traefik-dns01.nix's own applyScript format); this just writes it
  # verbatim. No chown to root:traefik-dns01 needed the way applyScript
  # itself does post-boot — that system user doesn't exist yet on this
  # live ISO, and that module's own "z /etc/traefik/traefik.env 0640
  # root traefik-dns01" tmpfiles rule fixes ownership/permissions on
  # every real boot regardless of what this write leaves behind. A
  # USB-provided traefik.env (secrets_usb/etc/traefik/traefik.env) was
  # already copied in wholesale by the blanket etc/ copy above — this
  # only ever runs when stage_71_dns01 itself collected values
  # interactively, never both.
  if [ "$(wiz_get have_traefik_dns01)" = "true" ]; then
    mkdir -p /mnt/persist/etc/traefik
    printf '%s' "$(wiz_get traefik_env_content)" > /mnt/persist/etc/traefik/traefik.env
    chmod 600 /mnt/persist/etc/traefik/traefik.env
  fi

  # SSO secrets. Two things here are ever typed by a human: LLDAP's
  # bootstrap admin password, and each user's own password from
  # 50-users.sh (retained in $WIZ as plainpw_<name> specifically for
  # this). Everything else here is a machine-to-machine credential that
  # each module's own *-provision-ldap-bind-user oneshot pushes into
  # LLDAP automatically on first boot; the wizard just needs to
  # generate a random value and leave it where that oneshot (and each
  # service itself) expects to find it. hex lengths match what every
  # secrets/extra-files/**/*.example file in this repo already
  # documents for these exact secrets.
  if [ "$(wiz_get feature_sso)" = "true" ]; then
    mkdir -p /mnt/persist/etc/lldap /mnt/persist/etc/dashboard-login /mnt/persist/etc/unix-ldap-login
    wiz_get ldap_admin_password > /mnt/persist/etc/lldap/ldap_user_pass
    openssl rand -hex 16 > /mnt/persist/etc/dashboard-login/ldap_password
    openssl rand -hex 16 > /mnt/persist/etc/unix-ldap-login/ldap_password
    chmod 600 /mnt/persist/etc/lldap/ldap_user_pass \
      /mnt/persist/etc/dashboard-login/ldap_password \
      /mnt/persist/etc/unix-ldap-login/ldap_password

    # One file per user, consumed and deleted by
    # modules/lldap.nix's lldap-seed-initial-passwords oneshot on first
    # boot — sets each wizard-created user's LLDAP password to match
    # their local Unix one, so SSO-gated login (dashboard, sudo) works
    # immediately instead of needing a manual LLDAP-admin-UI step.
    # Deliberately a separate, one-time file per user rather than
    # touching modules/lldap.nix's continuously-reconciled userConfigs
    # — see that module for why those stay password-less.
    mkdir -p /mnt/persist/etc/lldap/initial-passwords
    while IFS= read -r uname; do
      [ -z "$uname" ] && continue
      printf '%s' "$(wiz_get "plainpw_${uname}")" > "/mnt/persist/etc/lldap/initial-passwords/${uname}"
      chmod 600 "/mnt/persist/etc/lldap/initial-passwords/${uname}"
      wiz_unset "plainpw_${uname}"
    done <<< "$(wiz_get user_list)"

    if [ "$(wiz_get feature_jellyfin)" = "true" ]; then
      mkdir -p /mnt/persist/etc/jellyfin
      openssl rand -hex 16 > /mnt/persist/etc/jellyfin/ldap_bind_password
      chmod 600 /mnt/persist/etc/jellyfin/ldap_bind_password
    fi

    if [ "$(wiz_get feature_sso_authelia)" = "true" ]; then
      mkdir -p /mnt/persist/etc/authelia
      openssl rand -hex 32 > /mnt/persist/etc/authelia/jwt_secret
      openssl rand -hex 32 > /mnt/persist/etc/authelia/session_secret
      openssl rand -hex 32 > /mnt/persist/etc/authelia/storage_encryption_key
      openssl rand -hex 16 > /mnt/persist/etc/authelia/ldap_password
      # modules/authelia.nix's candidateOidcClients.filebrowser entry is
      # unconditionally enable = true, so these two are always required
      # once authelia itself is on — not gated on feature_filebrowser.
      # oidc_issuer_private_key.pem needs a real RSA key, not just random
      # bytes: Authelia signs OIDC tokens with it.
      openssl rand -hex 32 > /mnt/persist/etc/authelia/oidc_hmac_secret
      openssl genrsa -out /mnt/persist/etc/authelia/oidc_issuer_private_key.pem 2048 2>/dev/null
      chmod 600 /mnt/persist/etc/authelia/jwt_secret \
        /mnt/persist/etc/authelia/session_secret \
        /mnt/persist/etc/authelia/storage_encryption_key \
        /mnt/persist/etc/authelia/ldap_password \
        /mnt/persist/etc/authelia/oidc_hmac_secret \
        /mnt/persist/etc/authelia/oidc_issuer_private_key.pem

      # Confidential OIDC client secret + its argon2id hash, one pair per
      # client name — modules/authelia.nix reads the hash (Nix eval-time
      # builtins.readFile) to register that client, and the matching
      # service module (modules/filebrowser.nix, modules/minio.nix) reads
      # the plaintext the same way, so the two can never independently
      # drift the way a hash hardcoded into the repo did (broke on every
      # host except whichever one it was originally derived from — see
      # modules/authelia.nix's oidcSecretsDir comment).
      #
      # `argon2` (pkgs.libargon2, baked into this ISO's systemPackages),
      # not mkpasswd -m argon2id: confirmed the hard way, this repo's
      # nixpkgs pin's mkpasswd (whois 5.6.6 / libxcrypt 4.5.2) has no
      # argon2 support at all ("Invalid method 'argon2id'") — only
      # yescrypt/scrypt/bcrypt/sha512crypt/etc. argon2's `-e` flag prints
      # just the encoded PHC string (self-describing m/t/p params, so
      # Authelia can verify it regardless of which parameters were used
      # here) with nothing else to strip out.
      gen_oidc_client_secret() {
        local name="$1"
        local secret salt
        secret=$(openssl rand -hex 32)
        salt=$(openssl rand -hex 16)
        mkdir -p /mnt/persist/etc/authelia/oidc-clients
        printf '%s' "$secret" > "/mnt/persist/etc/authelia/oidc-clients/${name}_secret"
        printf '%s' "$secret" | argon2 "$salt" -id -t 3 -m 16 -p 4 -e \
          > "/mnt/persist/etc/authelia/oidc-clients/${name}_secret_hash"
        chmod 600 "/mnt/persist/etc/authelia/oidc-clients/${name}_secret" \
          "/mnt/persist/etc/authelia/oidc-clients/${name}_secret_hash"
      }

      # modules/filebrowser.nix reads its secret at eval time
      # (builtins.readFile, not a runtime *File option) whenever
      # ssoEnabled — the file has to exist before nixos-install even
      # evaluates the config, not just before FileBrowser starts. Caught
      # by the VM install test: without this, nixos-install fails
      # outright with "path .../filebrowser_secret does not exist".
      # candidateOidcClients.filebrowser is unconditionally enable = true
      # (matching modules/authelia.nix), so this runs regardless of
      # feature_filebrowser — same reasoning as oidc_hmac_secret above.
      gen_oidc_client_secret filebrowser
      if [ "$(wiz_get feature_filebrowser)" = "true" ]; then
        mkdir -p /mnt/persist/etc/filebrowser
        # Separate from the OIDC client secret above — this is
        # FileBrowser's own *local* break-glass admin account
        # (filebrowser-setup.service's FILEBROWSER_ADMIN_USER/PASSWORD,
        # see secrets/extra-files/persist/etc/filebrowser/admin.env.example),
        # required unconditionally by modules/filebrowser.nix's
        # EnvironmentFile — deliberately not the same username as any real
        # LLDAP user (see that .example file's own comment on why).
        {
          echo "FILEBROWSER_ADMIN_USER=admin"
          echo "FILEBROWSER_ADMIN_PASSWORD=$(openssl rand -hex 16)"
        } > /mnt/persist/etc/filebrowser/admin.env
        chmod 600 /mnt/persist/etc/filebrowser/admin.env
      fi

      # Same pattern for MinIO's console client — modules/minio.nix reads
      # this the same way filebrowser does, so MinIO's console OIDC login
      # no longer needs the plaintext secret hand-typed into
      # secrets/extra-files/persist/etc/minio/minio.env.
      # candidateOidcClients."minio-console" is unconditionally
      # enable = true too (matching filebrowser's own comment above), so
      # this runs regardless of feature_minio — Authelia registers this
      # client, and expects a matching hash, whether or not MinIO itself
      # is actually installed on this host.
      gen_oidc_client_secret minio-console

      # modules/frigate.nix's proxyAuthSecret is the same eval-time
      # readFile pattern, forced once frigate lands in
      # mySystem.sso.protectedServices (authelia.nix, gated on this same
      # feature_sso_authelia flag) — same fix, same reason.
      if [ "$(wiz_get feature_frigate)" = "true" ]; then
        mkdir -p /mnt/persist/etc/frigate
        openssl rand -hex 32 > /mnt/persist/etc/frigate/proxy_auth_secret
        chmod 600 /mnt/persist/etc/frigate/proxy_auth_secret
      fi
    fi
  fi

  wiz_msgbox "Installing NixOS" "Running nixos-install now — this can take a while (downloading/building packages). The console will show progress."

  # --impure: confirmed the hard way that nixos-install's own internal
  # nix invocation doesn't pick up NIX_CONFIG=pure-eval=false from this
  # shell's environment (unlike plain `nix build`) — modules/users.nix's
  # builtins.getEnv calls need real impure evaluation, not just the env
  # vars being exported.
  nixos-install --root /mnt --flake "$flake_attr" --no-root-password --impure

  # The authorized_keys write above (if any) happened before this
  # user even existed anywhere — this live ISO's own user database has
  # never heard of $first_user, so a chown right there couldn't have
  # resolved a real UID/GID, only nixos-install's activation above
  # actually creates the account. Left un-owned (root:root, from the
  # plain `mkdir`/redirect that wrote it), sshd's StrictModes silently
  # refuses that key outright — confirmed the hard way in a real Tier 3
  # run: publickey auth was declined without even attempting a
  # signature check, and password auth is off by default, so this
  # locked the account out of SSH entirely with no error surfaced
  # anywhere in the wizard's own flow. modules/users.nix's isNormalUser
  # gives every user the shared "users" group (not a same-named private
  # group), confirmed against a real installed system.
  if [ -n "$(wiz_get ssh_pubkey)" ]; then
    nixos-enter --root /mnt -c "chown -R '$first_user:users' '/home/$first_user/.ssh'"
  fi

  mkdir -p /mnt/persist/nixos-installer-output
  # host_dir already contains variables.nix alongside configuration.nix/
  # disko.nix — no separate top-level copy needed now that all three live
  # together. This copy is also modules/system-rebuild.nix's own source
  # of truth for this host's variables.nix on every future update (its
  # persistedVariablesFile) — not just a one-time "retrieve after
  # reboot" convenience, so don't remove/relocate it without updating
  # that module's path to match.
  cp -r "$host_dir" "/mnt/persist/nixos-installer-output/$instance"

  local sso_note=""
  if [ "$(wiz_get feature_sso)" = "true" ]; then
    sso_note="

SSO is enabled: once rebooted, each user you added can already log into the dashboard and (if enabled) console/sudo with the same password set for them during setup. LLDAP's own admin UI is at http://<this box's LAN IP>:17170, signed in as \"admin\" with the bootstrap password you set earlier — only needed if you want to manage accounts/groups directly there beyond what this wizard already set up."
  fi

  # modules/minio.nix's rootCredentialsFile (MINIO_ROOT_USER/PASSWORD) is
  # out-of-repo, same as Traefik's LINODE_TOKEN. The generation block
  # above (right after the secrets_usb copy) already guarantees a real
  # file exists whenever feature_minio is on, whether USB-provided or
  # auto-generated — the "still missing" branch below is
  # just the leftover safety net for that write somehow not happening
  # (e.g. /mnt/persist unwritable), so the admin still isn't left
  # chasing a silent ConditionPathExists no-start with nothing in this
  # wizard's own output explaining why — confirmed the hard way on a
  # real install before either the generation or this note existed.
  local minio_note=""
  if [ "$(wiz_get feature_minio)" = "true" ]; then
    if [ -f /mnt/persist/etc/minio/minio.env ]; then
      minio_note="

MinIO root credentials were generated automatically at /etc/minio/minio.env (left untouched if your secrets USB already provided one) — retrieve or rotate them there, or from the dashboard's Service Configuration page, after reboot."
    else
      minio_note="

MinIO is enabled but has no root credentials yet (/etc/minio/minio.env) — it will not start until you create one. See secrets/extra-files/persist/etc/minio/minio.env.example for the format, or scripts/migrate-oidc-client-secrets.sh's own comment if you're also missing its OIDC client secret."
    fi
  fi

  wiz_msgbox "Done" "Install complete.

Generated config was left at /persist/nixos-installer-output/ on the new system — retrieve it after reboot and drop it into hosts/$manufacturer/$instance/ in your real git checkout:
  ${instance}/variables.nix
  ${instance}/configuration.nix
  ${instance}/disko.nix
Commit configuration.nix and disko.nix. variables.nix is intentionally NOT committed (it's gitignored — see variables.nix.example at the repo root); don't delete /persist/nixos-installer-output/ though — every future update reads this host's variables.nix from there permanently, not just this once.

secrets/initial-passwords.env was NOT copied there (it only ever mattered for this install) — recreate it in your own checkout from secrets/initial-passwords.env.example if you'll be rebuilding this box from your workstation later.${sso_note}${minio_note}"

  if wiz_yesno "Reboot now?" "Unmount and reboot into the new system?"; then
    # `umount -R /mnt` alone isn't reliable here — confirmed the hard way
    # that it fails with "not mounted" when /mnt itself was never a
    # mountpoint (only its children are, e.g. /mnt/nix, /mnt/persist,
    # /mnt/boot from disko), leaving everything still mounted. Enumerate
    # every actual mount under /mnt and unmount deepest-first instead.
    local mnt
    for mnt in $(findmnt -R -o TARGET -n /mnt 2>/dev/null | sort -r); do
      umount "$mnt" 2>/dev/null || umount -l "$mnt" 2>/dev/null
    done
    # The /persist bind mount added above lives outside the /mnt subtree,
    # so the loop above never touches it.
    umount /persist 2>/dev/null || umount -l /persist 2>/dev/null
    zpool export "$(wiz_get pool_name)" 2>/dev/null
    reboot
  fi
}
