# Deploying `young`

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

Go back and fill in the `CHANGEME` values in `hosts/young/disko.nix` and
`modules/common.nix` with what you just found. The temporary root password
only matters for the SSH connections in steps 3–4 — it doesn't carry over
to the installed system (`beardedtek`'s real key, delivered separately in
step 4, is what you'll actually log in with afterward).

## 3. Import `rust` and create its two new datasets — before installing

**This has to happen now, before `nixos-anywhere` runs — not after.** The
config declares `/nix`, `/persist`, `/home`, etc. as ZFS datasets on `rust`.
The standard install-time mount step that `nixos-anywhere` relies on will
try to mount all of them, and that fails if `rust` isn't imported yet.

Still on the live installer, over SSH (or at the console):

```sh
# rust was last imported under a different host's ZFS hostid. Stamp this
# session's hostid to match what `young` will use (networking.hostId in
# hosts/young/configuration.nix) BEFORE importing, so the import "sticks" —
# otherwise it comes up mismatched again on first real boot too.
zgenhostid 975edc0d
zpool import -f rust

# The only two new datasets this setup needs — everything else already
# exists in `rust` and must not be touched. -o mountpoint=legacy is
# required: ZFS refuses to mount a native-mountpoint dataset at any path
# other than the one recorded in its own mountpoint property (a freshly
# created dataset inherits /rust/nix and /rust/persist from the parent
# `rust` dataset's own mountpoint=/rust — not /nix or /persist, which is
# what fileSystems."/nix"/"/persist" actually need). Skipping this is a
# guaranteed unbootable system: confirmed the hard way once already.
zfs create -o mountpoint=legacy rust/nix
zfs create -o mountpoint=legacy rust/persist
```

## 4. Mount everything `nixos-anywhere` needs under /mnt, then install

`nixos-anywhere`'s automatic disko-driven install only knows how to mount
what's declared in `disko.nix` — i.e. just the USB drive's ESP. It has no
idea `rust/nix`, `rust/persist`, or `rust/home` exist, so left to its own
devices it silently writes the entire system (and the `--extra-files`
payload) onto whatever ephemeral storage backs `/mnt` in the live
environment instead of onto the pool. Split the run into phases and mount
these by hand in between so the install actually lands somewhere
persistent.

**4a. Partition just the USB drive** (from your workstation, `CHANGEME`
values from step 2 already filled in):

```sh
nix run github:nix-community/nixos-anywhere -- \
  --phases disko \
  --flake .#young \
  root@<live-ip>
```

**4b. Mount the ZFS targets under /mnt** (back on the live installer):

```sh
mkdir -p /mnt/nix /mnt/persist /mnt/home
mount -t zfs rust/nix /mnt/nix
mount -t zfs rust/persist /mnt/persist

# rust/home is a pre-existing, native-mountpoint dataset (mountpoint=/home)
# with real data already on it — leave its property alone and bind-mount
# instead of remounting, so the beardedtek SSH key delivered via
# --extra-files in the next step lands on real, persistent storage rather
# than disappearing on reboot:
zfs mount rust/home 2>/dev/null || true
mount --bind /home /mnt/home
```

**4c. Install** (from your workstation again):

```sh
nix run github:nix-community/nixos-anywhere -- \
  --phases install,reboot \
  --flake .#young \
  --extra-files ./secrets/extra-files \
  root@<live-ip>
```

This installs against the filesystems mounted in 4b, copies
`secrets/extra-files/*` onto them (the Nebula config lands on `/etc/nebula`
→ `rust/persist`, the SSH key on `/home/beardedtek/.ssh/authorized_keys` →
`rust/home` — both real, persistent mounts now), then its `reboot` phase
unmounts everything and exports `rust` cleanly before rebooting.

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
