#!/usr/bin/env bash
# One-time migration for an already-installed host: computes the
# argon2id hash modules/authelia.nix needs for each confidential OIDC
# client, from that client's own plaintext secret at
# /persist/etc/authelia/oidc-clients/<name>_secret. A fresh install's
# wizard (hosts/installer/wizard/stages/90-install.sh) does this
# automatically; this script is the equivalent one-time step for a host
# that was installed before that existed, or is only now enabling a
# given client for the first time.
#
# If a client's plaintext secret doesn't exist yet, this generates one
# (openssl rand -hex 32) rather than requiring it to be pre-populated —
# safe for a client with no prior real secret (e.g. minio-console before
# this migration ever ran). For a client that already has a real secret
# in use (e.g. filebrowser, if OIDC login previously worked), that
# existing plaintext is reused as-is so this never silently invalidates
# a working login.
#
# Run as root: sudo bash scripts/migrate-oidc-client-secrets.sh [names...]
# Defaults to filebrowser and minio-console (modules/authelia.nix's own
# two unconditionally-enabled candidateOidcClients) if no names given.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this as root (sudo bash $0)." >&2
  exit 1
fi

SECRETS_DIR="/persist/etc/authelia/oidc-clients"
mkdir -p "$SECRETS_DIR"

names=("$@")
if [ "${#names[@]}" -eq 0 ]; then
  names=(filebrowser minio-console)
fi

for name in "${names[@]}"; do
  secret_file="$SECRETS_DIR/${name}_secret"
  hash_file="$SECRETS_DIR/${name}_secret_hash"

  if [ -s "$secret_file" ]; then
    echo "== $name: reusing existing secret at $secret_file =="
  else
    echo "== $name: no existing secret, generating a new one =="
    openssl rand -hex 32 > "$secret_file"
  fi

  secret=$(cat "$secret_file")
  salt=$(openssl rand -hex 16)
  # `argon2` (pkgs.libargon2), same tool and parameters (m=65536,t=3,p=4
  # — matching what this repo's original hardcoded hashes were generated
  # with) as hosts/installer/wizard/stages/90-install.sh's own
  # gen_oidc_client_secret — NOT mkpasswd: confirmed the hard way, this
  # nixpkgs pin's mkpasswd (whois 5.6.6 / libxcrypt 4.5.2) has no argon2
  # support at all ("Invalid method 'argon2id'"), only
  # yescrypt/scrypt/bcrypt/sha512crypt/etc. `-e` prints just the encoded
  # PHC string, nothing else to strip out.
  # --extra-experimental-features explicit rather than relying on ambient
  # nix.conf: confirmed the hard way that running this under a plain
  # `sudo bash -c '...'` picked up root's own (flakes-disabled) nix
  # config instead of the invoking user's, silently producing empty
  # output with no error.
  hash=$(printf '%s' "$secret" | nix --extra-experimental-features "nix-command flakes" run nixpkgs#libargon2 -- "$salt" -id -t 3 -m 16 -p 4 -e)
  if [ -z "$hash" ]; then
    echo "!! $name: argon2 produced no output, aborting before writing an empty hash file." >&2
    exit 1
  fi
  echo "$name hash: $hash"
  printf '%s' "$hash" > "$hash_file"
done

chmod 600 "$SECRETS_DIR"/*
echo
echo "Done. Contents of $SECRETS_DIR:"
ls -la "$SECRETS_DIR"
