---
title: nixos-anywhere
linkTitle: nixos-anywhere
weight: 20
description: Manual, scriptable installation from a workstation, driven by nixos-anywhere.
---

The manual path: you edit the flake's config files yourself, then push
the install from another machine using
[`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere). More
steps than the [ISO installer](/docs/installation/iso/), but scriptable
and repeatable — a good fit if you're already managing this as
infrastructure-as-code, or want to adopt an existing ZFS pool with a
non-standard layout the wizard doesn't ask about.

## 0. Set up your host and fill in the placeholders

Copy `hosts/terramaster/f4-245/` (the generic template) to
`hosts/<manufacturer>/<instance-name>/`, and set
`mySystem.manufacturer`/`mySystem.model` in `variables.nix` to match.
Then fill in every `CHANGEME` marker (`grep -rn CHANGEME .` finds them
all) — your boot drive's `/dev/disk/by-id/...` path and your LAN
interface name are the two you can't know until you've booted the live
installer once (step 2 below).

**Secrets** (gitignored, never committed) live under
`secrets/extra-files/`, mirroring the target filesystem 1:1 — copy each
`*.example` file next to itself, drop the `.example` suffix, and fill in
real values. At minimum you need `secrets/initial-passwords.env` (a real
password hash per user in `mySystem.users`, via `mkpasswd -m sha-512`)
and an SSH public key under
`secrets/extra-files/home/<your-user>/.ssh/authorized_keys`. Everything
else under `secrets/extra-files/` is only needed for whichever services
you enable in `variables.nix` — each `.example` file explains what goes
in it and which feature flag gates it.

Every command below that builds or deploys the box needs your initial
passwords sourced into the environment first:

```sh
set -a; source secrets/initial-passwords.env; set +a
```

## 1. Boot a live installer

Flash the stock NixOS minimal ISO to a USB drive, boot your NAS from it,
and set a temporary root password (`passwd`) so `nixos-anywhere` can
reach it over SSH:

```sh
passwd
ip addr                     # confirm it has an IP, note it down
ls -la /dev/disk/by-id/     # your boot drive's stable id
ip link                     # your real LAN interface name
```

Go fill in the `CHANGEME` placeholders from step 0 with what you just
found.

## 2. If adopting an existing ZFS pool: import it and fix mountpoints first

**Skip this step if you're using a blank-drive layout** — `disko` handles
that case entirely on its own.

If you're adopting a pool that already has data on it, this has to happen
*before* `nixos-anywhere` runs, still on the live installer:

```sh
zpool import -f <your-pool>
```

Every dataset your config mounts via `fileSystems.*` — including the
pool's own top-level dataset, easy to forget since it's not usually
thought of as "a dataset" — needs `mountpoint=legacy`, or ZFS's own
auto-mount will fight with NixOS's boot-time mount units. See
[Architecture](/docs/architecture/#storage-design) for exactly why. For
each dataset (illustrated here with an example pool called `tank` —
replace with your own pool and dataset names throughout):

```sh
zfs create -o mountpoint=legacy tank/nix
zfs create -o mountpoint=legacy tank/persist
zfs set mountpoint=legacy tank
zfs set mountpoint=legacy tank/home
zfs set mountpoint=legacy tank/media
zfs set mountpoint=legacy tank/data
# ...and any other existing dataset your fileSystems.* entries reference
```

## 3. Mount everything, then install

`nixos-anywhere`'s automatic install only knows how to mount what's
declared in `disko.nix` — an adopted pool's datasets need mounting by
hand first, or the install (and the `--extra-files` secrets payload)
silently lands on ephemeral scratch space instead of your real pool.

**3a. Partition just the boot drive:**

```sh
nix run github:nix-community/nixos-anywhere -- \
  --phases disko \
  --flake .#<your-instance> \
  root@<live-installer-ip>
```

**3b. Mount your pool's datasets under `/mnt`** (back on the live
installer, skip if using blank drives — `disko` already did this):

```sh
mkdir -p /mnt/nix /mnt/persist /mnt/home
mount -t zfs tank/nix /mnt/nix
mount -t zfs tank/persist /mnt/persist
mount -t zfs tank/home /mnt/home
# ...and any other dataset from step 2
```

**3c. Install** (note `--option pure-eval false`, not `--impure` —
`nixos-anywhere`'s own argument parser doesn't recognize `--impure`):

```sh
set -a; source secrets/initial-passwords.env; set +a
nix run github:nix-community/nixos-anywhere -- \
  --option pure-eval false \
  --phases install,reboot \
  --flake .#<your-instance> \
  --extra-files ./secrets/extra-files \
  root@<live-installer-ip>
```

This installs onto whatever's mounted, copies your secrets onto it, then
reboots.

## 4. First boot and one-time fixups

Remove the installer USB (or fix the boot order) so it boots from the
internal drive. Then, once booted:

```sh
# Fix SSH key permissions (a raw file copy doesn't guarantee these):
sudo chown -R <your-user>:users /home/<your-user>/.ssh
chmod 700 /home/<your-user>/.ssh
chmod 600 /home/<your-user>/.ssh/authorized_keys

# Samba has its own password database, separate from your Unix login —
# set one for each user who needs file-share access:
sudo smbpasswd -a <your-user>
```

If you adopted an existing media library, the media stack's services
(Jellyfin, Sonarr, Radarr, qBittorrent, Seerr) each run as their own
system user and need shared group access to it once —
[Architecture](/docs/architecture/#services) covers the exact commands
under "Shared media/data access."

## 5. Verify

- `zpool status -v <your-pool>` — all members `ONLINE`, no errors.
- Reboot once, confirm a marker file written to `/` disappears (tmpfs)
  and one written to `/persist` survives.
- Connect to a Samba share and mount NFS from a client.
- Open the [web dashboard](/docs/usage/webui/) and confirm the live
  status widgets update.
- Walk through [Usage](/docs/usage/) for each service you enabled.
