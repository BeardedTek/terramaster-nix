# Deploying `young`

This flake has been validated with `nix flake check` and a full `--dry-run`
build of both `nixosConfigurations.young` and `.installer`, using a NixOS
26.05 environment (`wsl -d NixOS` on this machine). Both evaluate cleanly
with zero errors. That confirms the config is internally consistent —
it does **not** confirm the box actually boots this way; that's what the
verification checklist at the end of this doc is for.

## 0. Fill in the placeholders first

Nothing below will work until these are real values.

**In the repo (CHANGEME markers — `grep -rn CHANGEME .` to find them all):**

| File | Placeholder | Replace with |
|---|---|---|
| `hosts/young/disko.nix` | `CHANGEME-usb-boot-drive` | the USB drive's `/dev/disk/by-id/...` path — you can't know this until step 2 |
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
| `secrets/extra-files/etc/nebula/config.yaml` | already in place — your real Nebula config, CA/cert/key embedded |
| `secrets/extra-files/home/beardedtek/.ssh/authorized_keys` | copy `authorized_keys.example` in the same folder, drop in your real public key, drop the `.example` suffix |

Everything under `secrets/extra-files/` mirrors the target's filesystem
1:1 (e.g. `secrets/extra-files/etc/nebula/config.yaml` → `/etc/nebula/config.yaml`
on the deployed box). One `--extra-files` flag copies the whole tree at
once (step 5).

## 1. Build and flash the installer ISO

From this repo, on a machine with Nix (this machine's `wsl -d NixOS` works):

```sh
INSTALLER_SSH_KEY="$(cat secrets/extra-files/home/beardedtek/.ssh/authorized_keys)" \
  nix build --impure .#nixosConfigurations.installer.config.system.build.isoImage
```

`--impure` is required: the key is read from an environment variable
(`builtins.getEnv`) on purpose, since a gitignored file wouldn't be visible
to a normal (pure) flake evaluation anyway.

Flash `result/iso/*.iso` to a **separate external USB drive** — not the
F4-245's internal 256GB drive, which is the install *target*, not the boot
media for this step. (Community reports on similar TerraMaster models say
the internal USB header only boots TerraMaster's own TOS install stub, not
a general live OS — hence booting the installer externally.)

## 2. Boot the box from the installer, gather two facts

Plug the flashed USB into an external port on the F4-245 and boot from it
(may need a one-time physical BIOS/UEFI boot-menu selection — unconfirmed
whether this model allows a fully headless boot-order change). Once it's
up and reachable over SSH as root:

```sh
ssh root@<live-ip>
ls -la /dev/disk/by-id/     # → the internal 256GB USB drive's stable id
ip link                     # → the real LAN interface name
```

Go back and fill in the `CHANGEME` values in `hosts/young/disko.nix` and
`modules/common.nix` with what you just found.

## 3. Import `rust` and create its two new datasets — before installing

**This has to happen now, before `nixos-anywhere` runs — not after.** The
config declares `/nix`, `/persist`, `/home`, etc. as ZFS datasets on `rust`.
The standard install-time mount step that `nixos-anywhere` relies on will
try to mount all of them, and that fails if `rust` isn't imported yet.

Still on the live installer, over SSH:

```sh
# rust was last imported under a different host's ZFS hostid. Stamp this
# session's hostid to match what `young` will use (networking.hostId in
# hosts/young/configuration.nix) BEFORE importing, so the import "sticks" —
# otherwise it comes up mismatched again on first real boot too.
zgenhostid 975edc0d
zpool import -f rust

# The only two new datasets this setup needs — everything else already
# exists in `rust` and must not be touched:
zfs create rust/nix
zfs create rust/persist
```

## 4. Run nixos-anywhere

From your workstation (not the live installer), with the `CHANGEME` values
from step 2 already filled in:

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake .#young \
  --extra-files ./secrets/extra-files \
  root@<live-ip>
```

This partitions **only** the USB drive per `disko.nix` (the 4 HDDs are
untouched), mounts every declared filesystem — `rust`'s datasets included,
already imported in step 3 — installs the system, and copies
`secrets/extra-files/*` onto the mounted target: the Nebula config lands on
`/etc/nebula` (`rust/persist`, survives the tmpfs root) and the SSH key
lands on `/home/beardedtek/.ssh/authorized_keys` (`rust/home`, a real
persistent mount).

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
