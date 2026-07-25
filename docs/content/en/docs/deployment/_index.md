---
title: Deployment
linkTitle: Deployment
weight: 20
description: Step-by-step procedure for installing Bearded NAS onto young from a blank machine.
---

This flake has been validated with `nix flake check` and a full `--dry-run`
build of `nixosConfigurations.young`, using a NixOS 26.05 environment
(`wsl -d NixOS` on this machine). It evaluates cleanly with zero errors.
That confirms the config is internally consistent — it does **not**
confirm the box actually boots this way; that's what the verification
checklist at the end of this doc is for.

Bootstrapping uses the **stock NixOS minimal installer ISO** (no custom
image needed) — the F4-245 has a monitor and keyboard attached for this,
so there's no need to pre-bake an SSH key into a custom ISO just for
headless access.

## 0. Fill in the placeholders first

Nothing below will work until these are real values.

**In the repo (CHANGEME markers — `grep -rn CHANGEME .` to find them all):**

| File | Placeholder | Replace with |
|---|---|---|
| `hosts/terramaster/young/disko.nix` | `CHANGEME-usb-boot-drive` | the USB drive's `/dev/disk/by-id/...` path — you can't know this until step 2 |
| `modules/common.nix` | `mySystem.lanInterface` default, `"CHANGEME-lan-if"` | your LAN interface name, e.g. `eno1` — found in step 2. Single source of truth: both `samba.nix` and `nfs.nix` read it from here. |

There's no LAN CIDR to fill in for NFS — `nfs.nix` detects whatever
subnet is currently live on `mySystem.lanInterface` at every `nfs-server`
start (via `ip route show ... scope link`) and allows that, alongside the
Nebula mesh (`10.100.0.0/24`, static) unconditionally. Worth knowing: this
means NFS opens to *whatever network the box is plugged into* on that
interface with no manual review — fine for a home LAN that doesn't change,
worth reconsidering if it ever might.

**In the secrets tree (gitignored — never committed, `git status` should
never show these as trackable):**

| Path | What goes here |
|---|---|
| `secrets/extra-files/persist/etc/nebula/config.yaml` | already in place — your real Nebula config, CA/cert/key embedded. Lives under `persist/` (not `etc/`) because `--extra-files` writes directly onto whatever's mounted under `/mnt` during install (step 4b) — `/mnt/persist` is the real `rust/persist` dataset at that point, `/mnt/etc` is not (it's ephemeral install-scratch space, gone by first boot, well before impermanence's `/etc/nebula` bind-mount from `/persist/etc/nebula` even exists to shadow it) |
| `secrets/extra-files/home/beardedtek/.ssh/authorized_keys` | copy `authorized_keys.example` in the same folder, drop in your real public key, drop the `.example` suffix |
| `secrets/initial-passwords.env` | copy `initial-passwords.env.example`, fill in real `mkpasswd -m sha-512` output for `ROOT_INITIAL_HASH` plus one `<NAME_UPPERCASE>_INITIAL_HASH` per entry in `variables.nix`'s `mySystem.users` (currently `BEARDEDTEK_INITIAL_HASH`, `DYOUNG_INITIAL_HASH`) |
| `secrets/extra-files/persist/etc/traefik/traefik.env` | copy `traefik.env.example` in the same folder, fill in the real Linode API token as `LINODE_TOKEN` — used for the DNS-01 challenge in `modules/traefik.nix` |
| `secrets/extra-files/persist/etc/minio/minio.env` | only if `mySystem.features.minio.enable = true;` — copy `minio.env.example` in the same folder, fill in real `MINIO_ROOT_USER`/`MINIO_ROOT_PASSWORD` values. Without it, MinIO just doesn't start (see `modules/minio.nix`) — nothing else depends on it |
| `secrets/extra-files/persist/etc/filebrowser/admin.env` | only if `mySystem.features.filebrowser.enable = true;` — copy `admin.env.example` in the same folder, fill in real `FILEBROWSER_ADMIN_USER`/`FILEBROWSER_ADMIN_PASSWORD` values. Only read once, to create the initial admin account (see `modules/filebrowser.nix`) — a password changed later through FileBrowser's own UI is never overwritten by this file again |

Everything under `secrets/extra-files/` mirrors the target's filesystem
1:1 (e.g. `secrets/extra-files/etc/nebula/config.yaml` → `/etc/nebula/config.yaml`
on the deployed box). One `--extra-files` flag copies the whole tree at
once (step 5). `secrets/initial-passwords.env` is different — it's read
locally at *build* time (`modules/users.nix`, `builtins.getEnv` per name
in `mySystem.users` plus `root`), not delivered to the target at all, so
**every** command that builds or deploys `young` (steps 4c below, and any
later `nixos-rebuild switch --target-host ...`) needs both of:

```sh
set -a; source secrets/initial-passwords.env; set +a
```

and impure evaluation enabled on the command itself — `--impure` for a
plain `nix build`/`nixos-rebuild switch`, but **not** for `nixos-anywhere`:
everything after its own `--` is parsed by nixos-anywhere's own argument
parser, which doesn't recognize `--impure` and errors out. For
`nixos-anywhere` specifically, use `--option pure-eval false` instead
(its own `--option <key> <value>` flag forwards a real nix setting to its
internal build invocations — confirmed this achieves the same effect as
`--impure` and that the assertions below still fire correctly if the env
vars aren't set). `beardedtek`/`dyoung`/`root` all use
`initialHashedPassword` with `users.mutableUsers = true` — applied only
once, when each account is first created; after that, whatever the user
sets via `passwd` persists across every future rebuild untouched (verified
against NixOS's actual activation script, not just the docs). The
tradeoff: you can't force-rotate a password later by editing this file —
once an account exists, its value here is permanently inert for that
account. Rotating means logging in and running `passwd`/`chpasswd`
directly.

## 1. Download and flash the stock installer ISO

Get the official NixOS 26.05 minimal ISO from
https://nixos.org/download (match the `nixos-26.05` release this flake is
pinned to — a different release can still work, but keep it close). Flash
it to a **separate external USB drive** — not the F4-245's internal drive,
which is the install *target*, not the boot media for this step. (Community
reports on similar TerraMaster models say the internal USB header only
boots TerraMaster's own TOS install stub, not a general live OS — hence
booting the installer externally.)

## 2. Boot the box at the console, gather two facts, enable SSH access

Plug the flashed USB into an external port on the F4-245, attach the
monitor/keyboard, and boot from it (may need a one-time BIOS/UEFI
boot-menu selection to pick the USB drive). Once you're at the live
installer's console:

```sh
# The live ISO's root account has no password set (SSH access is refused
# until it does) — set a temporary one so nixos-anywhere can connect from
# your workstation in step 4:
passwd

ip addr                     # → confirm it got a DHCP address; note the IP
ls -la /dev/disk/by-id/     # → the internal USB drive's stable id
ip link                     # → the real LAN interface name
```

Go back and fill in the `CHANGEME` values in `hosts/terramaster/young/disko.nix` and
`modules/common.nix` with what you just found. The temporary root password
only matters for the SSH connections in steps 3–4 — it doesn't carry over
to the installed system (`beardedtek`'s real key, delivered separately in
step 4, is what you'll actually log in with afterward).

## 3. Import `rust` and fix every dataset's mountpoint property — before installing

**This has to happen now, before `nixos-anywhere` runs — not after.** The
config declares `/nix`, `/persist`, `/home`, etc. as ZFS datasets on `rust`.
The standard install-time mount step that `nixos-anywhere` relies on will
try to mount all of them, and that fails if `rust` isn't imported yet.

Still on the live installer, over SSH (or at the console):

```sh
# rust was last imported under a different host's ZFS hostid. Stamp this
# session's hostid to match what `young` will use (networking.hostId in
# hosts/terramaster/young/configuration.nix) BEFORE importing, so the import "sticks" —
# otherwise it comes up mismatched again on first real boot too.
zgenhostid 975edc0d
zpool import -f rust
```

**Every** dataset referenced by a `fileSystems.*` entry in this config
needs `mountpoint=legacy` — not just the two new ones. This isn't optional
and isn't just about path mismatches: `zpool import` auto-mounts any
dataset with a *native* (non-legacy) mountpoint and `canmount=on` as part
of the import itself, inside the initrd's own mount namespace. NixOS's
own systemd-generated `sysroot-*.mount` units then try to mount that same
already-mounted dataset again at `/sysroot/...`, and that conflict fails
outright — confirmed the hard way, on both a freshly-created dataset with
a mismatched path (`rust/nix`) *and* a pre-existing one with a matching
path (`rust/home`). Legacy datasets are never auto-mounted by ZFS, only
ever mounted explicitly — which is exactly what NixOS's units do.

```sh
# New datasets this setup needs — everything else already exists in
# `rust` and isn't being created, just having its mountpoint property
# changed (metadata-only, doesn't touch/move/delete any data):
zfs create -o mountpoint=legacy rust/nix
zfs create -o mountpoint=legacy rust/persist

# Pre-existing datasets — same fix, for the same reason. Includes the
# pool's own top-level dataset ("rust" itself, mountpoint=/rust) — easy to
# miss since it's not a `fileSystems.*` entry you'd naturally think to
# check, but it's just as native-mountpoint/canmount=on as its children by
# default, and gets auto-mounted (then can get silently re-mounted later,
# orphaning everything nested under it) exactly the same way if left alone:
zfs set mountpoint=legacy rust
zfs set mountpoint=legacy rust/home
zfs set mountpoint=legacy rust/libdocker
zfs set mountpoint=legacy rust/media
zfs set mountpoint=legacy rust/data
zfs set mountpoint=legacy rust/config
zfs set mountpoint=legacy rust/backups
zfs set mountpoint=legacy rust/docker
```

## 4. Mount everything `nixos-anywhere` needs under /mnt, then install

`nixos-anywhere`'s automatic disko-driven install only knows how to mount
what's declared in `disko.nix` — i.e. just the USB drive's ESP. It has no
idea any of `rust`'s datasets exist, so left to its own devices it
silently writes the entire system (and the `--extra-files` payload) onto
whatever ephemeral storage backs `/mnt` in the live environment instead of
onto the pool. Split the run into phases and mount these by hand in
between so the install actually lands somewhere persistent.

**4a. Partition just the USB drive** (from your workstation, `CHANGEME`
values from step 2 already filled in):

```sh
nix run github:nix-community/nixos-anywhere -- \
  --phases disko \
  --flake .#young \
  root@<live-ip>
```

**4b. Mount the ZFS targets under /mnt** (back on the live installer — now
that everything is `legacy`, this is a plain explicit mount for all of
them, no bind-mount workaround needed):

```sh
mkdir -p /mnt/nix /mnt/persist /mnt/home /mnt/var/lib/docker /mnt/rust
mount -t zfs rust/nix /mnt/nix
mount -t zfs rust/persist /mnt/persist
mount -t zfs rust/home /mnt/home
mount -t zfs rust/libdocker /mnt/var/lib/docker
# Mount the pool's own top-level dataset before its children — same
# reasoning as everywhere else here, it's just as real a managed mount now:
mount -t zfs rust /mnt/rust
mkdir -p /mnt/rust/media /mnt/rust/data /mnt/rust/config /mnt/rust/backups /mnt/rust/docker
mount -t zfs rust/media /mnt/rust/media
mount -t zfs rust/data /mnt/rust/data
mount -t zfs rust/config /mnt/rust/config
mount -t zfs rust/backups /mnt/rust/backups
mount -t zfs rust/docker /mnt/rust/docker
```

**4c. Install** (from your workstation again — note `--option pure-eval
false`, *not* `--impure`: nixos-anywhere's own argument parser doesn't
recognize `--impure` and will just dump its usage text if you pass it):

```sh
set -a; source secrets/initial-passwords.env; set +a
nix run github:nix-community/nixos-anywhere -- \
  --option pure-eval false \
  --phases install,reboot \
  --flake .#young \
  --extra-files ./secrets/extra-files \
  root@<live-ip>
```

This installs against the filesystems mounted in 4b, copies
`secrets/extra-files/*` onto them (the Nebula config lands on
`/persist/etc/nebula` → `rust/persist`, the SSH key on
`/home/beardedtek/.ssh/authorized_keys` → `rust/home` — both real,
persistent mounts now), then its `reboot` phase unmounts everything and
exports `rust` cleanly before rebooting.

## 5. First reboot onto the internal drive

Remove the external installer USB (or fix the BIOS boot order) so the box
boots from the internal 256GB drive from now on. `rust` should auto-import
without `-f` on this and every later boot, since its stored hostid now
matches `networking.hostId`.

## 6. Post-boot one-time fixups

```sh
# A raw file copy doesn't guarantee correct permissions, and SSH's
# StrictModes will refuse a wrongly-permissioned authorized_keys:
sudo chown -R beardedtek:users /home/beardedtek/.ssh
chmod 700 /home/beardedtek/.ssh
chmod 600 /home/beardedtek/.ssh/authorized_keys

# Samba has its own password database, separate from Unix login:
sudo smbpasswd -a beardedtek
sudo smbpasswd -a dyoung

# One-time: let jellyfin/sonarr/radarr/qbittorrent/seerr (each its own
# user/group) share access to the existing /rust/media library and
# /rust/data downloads directory via mediagroup, without loosening either
# to world-readable/writable. Safe to re-run; only needed once per fresh
# dataset, not on every rebuild.
sudo chgrp -R mediagroup /rust/media /rust/data
sudo chmod -R g+rwX /rust/media /rust/data
sudo find /rust/media /rust/data -type d -exec chmod g+s {} +
```

## 7. Verify

- `zpool status -v rust` — all 4 members ONLINE, no errors.
- `zfs list` — same datasets/used-space as before migration, plus the two
  new ones (`rust/nix`, `rust/persist`).
- Reboot once: write a marker file to `/` and to `/persist`; after reboot,
  the `/` marker should be gone (tmpfs) and the `/persist` one should
  still be there.
- `smbclient -L //young -U beardedtek` and an NFS mount round-trip from a
  client.
- Jellyfin (`http://young:8096`): force a transcode, confirm VAAPI engages
  (Dashboard → Playback, or `intel_gpu_top` on the box) rather than falling
  back to software encoding.
- Sonarr/Radarr/Jackett web UIs reachable, can see `/rust/media` and
  `/rust/data`.
- Jellyseerr/Seerr (`http://young:5055`) reachable — `systemctl status seerr.service`.
- `systemctl status nebula`, then ping the lighthouse over the mesh and
  confirm SSH still works over the Nebula IP as a second path in.
- Dashboard (`http://young:8097`, or via Traefik once DNS is set up):
  confirm the live metrics on the home page actually update (disk/CPU/
  memory/network), and that `systemctl status dashboard-metrics.timer` is
  active.
- Frigate (`http://young:8098` locally, or via Traefik):
  `sudo journalctl -u frigate | grep -i password` for the auto-generated
  admin login on first boot.
- Home Assistant (`http://young:8123` locally, or via Traefik): complete
  the onboarding wizard, then confirm `systemctl status
  hass-install-hacs.service` ran successfully and
  `/var/lib/hass/custom_components/hacs` exists before trying to enable
  HACS from Settings → Devices & Services.
- `systemctl status mosquitto` active; `mosquitto_sub -h young -t '#' -v`
  from another machine on the LAN/mesh to confirm the broker accepts
  anonymous connections.
