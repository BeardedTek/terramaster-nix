# Architecture: `young`

Design rationale for this flake — what each piece is for and why it's built
this way. `docs/DEPLOYMENT.md` is the step-by-step install procedure;
`docs/TROUBLESHOOTING.md` is the catalog of failure modes hit (and fixed)
while bringing this box up. This doc is the "why" in between.

## Hardware

TerraMaster F4-245: 4-bay NAS, Intel N-series CPU (QuickSync-capable, iHD
driver generation), 16GB DDR4-3200 RAM, 4x 6TB HDDs, 256GB drive in the
internal USB slot used as the boot/system drive.

## Storage design

### The `rust` pool is pre-existing and untouched by disko

`rust` (RAIDZ1 across the 4 HDDs) already existed before this flake, with
data already on it. `hosts/young/disko.nix` only ever partitions the
**256GB USB drive** (a single ESP, vfat, mounted `/boot`) — there is no
disko config for the 4 HDDs at all, on purpose. `rust` is *imported*, never
created or formatted. If disko ever grows a config block referencing any
`rust/*` dataset, that's a bug — nixos-anywhere would wipe it on install.

### Root is tmpfs; only `/nix` and `/persist` survive a reboot

The 256GB USB drive backs `/boot` and nothing else. `/` is `tmpfs` (RAM,
`size=2G`), so nothing routine gets written to the flash drive — the only
thing that changes it is a bootloader/kernel update on generation switches.
Two new ZFS datasets carry everything else:

- `rust/nix` → `/nix` (the Nix store)
- `rust/persist` → `/persist` (state that must survive a reboot despite
  the RAM root — see below)

The [`nix-community/impermanence`](https://github.com/nix-community/impermanence)
module (`environment.persistence."/persist"` in
`hosts/young/configuration.nix`) bind-mounts specific paths from `/persist`
back onto the tmpfs root at boot. Anything not explicitly listed there is
gone on every reboot.

**Consequence, stated plainly:** if `rust` is ever unavailable at boot
(drive unplugged, controller fault), the box won't boot at all — `/nix`
and `/persist` both depend on it. This is a deliberate tradeoff for
minimizing USB flash wear, not an oversight.

### Every `rust` dataset — including `rust` itself — is `mountpoint=legacy`

This is the single most important, least obvious fact about this pool.
ZFS auto-mounts any dataset with a *native* (non-legacy) mountpoint and
`canmount=on` as part of `zpool import`/`zfs mount -a`, entirely outside
NixOS's own systemd-generated mount units for the same paths. When both
try to own the same mountpoint, the result ranges from an outright mount
failure to a silent, much nastier bug: a dataset gets mounted successfully,
then something re-triggers ZFS's own auto-mount later, and the **second**
mount shadows/orphans whatever was already nested inside the first one.

Every dataset this config references via `fileSystems.*` — including the
pool's own top-level `rust` dataset (`fileSystems."/rust"` in
`hosts/young/configuration.nix`), not just its children — must be
`mountpoint=legacy`. See `docs/TROUBLESHOOTING.md` for the exact failure
signatures this produces when missed, and `docs/DEPLOYMENT.md` step 3 for
the one-time `zfs set` commands.

### ZFS dataset map

| Dataset | Mountpoint | New or pre-existing |
|---|---|---|
| `rust` | `/rust` | pre-existing |
| `rust/nix` | `/nix` | new |
| `rust/persist` | `/persist` | new |
| `rust/home` | `/home` | pre-existing |
| `rust/libdocker` | `/var/lib/docker` | pre-existing (unused by this config — kept mounted so old data isn't orphaned) |
| `rust/media` | `/rust/media` | pre-existing |
| `rust/data` | `/rust/data` | pre-existing |
| `rust/config` | `/rust/config` | pre-existing, currently unused |
| `rust/backups` | `/rust/backups` | pre-existing, reserved for future manual `zfs send`/`snapshot` use — no automated backup tooling (sanoid/syncoid) by design, kept simple |
| `rust/docker` | `/rust/docker` | pre-existing |

All mounted `fsType = "zfs"`, all `mountpoint=legacy` on the pool side.

## What's persisted, and why

`environment.persistence."/persist"` in `hosts/young/configuration.nix`
lists two kinds of paths:

**Whole directories** (`directories = [...]`): each service's state dir
under `/var/lib/<service>` (Samba, Jellyfin, Sonarr, Radarr, Jackett,
Seerr, qBittorrent, Traefik), plus:
- `/var/lib/nixos` — NixOS's dynamic uid/gid allocation state for every
  normal and system user. Without this, every reboot would reassign
  UIDs/GIDs, silently breaking ownership on every ZFS-backed path.
- `/etc/nebula`, `/etc/traefik` — config/secret files for services that
  read them directly from disk rather than through a NixOS option (Nebula's
  own `config.yaml`, Traefik's `LINODE_TOKEN` env file).

**Individual files** (`files = [...]`):
- `/etc/machine-id`
- The four SSH host key files (`ssh_host_rsa_key`/`.pub`,
  `ssh_host_ed25519_key`/`.pub`) — deliberately **not** the whole `/etc/ssh`
  directory. See `docs/TROUBLESHOOTING.md` for why that distinction matters.

## Users and passwords

Three accounts: `root`, `beardedtek` (admin), `dyoung` (share access) —
both `beardedtek` and `dyoung` have `wheel` (sudo, password-required via
`security.sudo.wheelNeedsPassword = true`). Neither has Samba access
extended to `root`.

`users.mutableUsers = true` plus `initialHashedPassword` for all three
accounts is a deliberate, specific choice, not the default pattern most
NixOS configs use. The requirement was: passwords provided as out-of-repo
secrets, but genuinely self-service changeable via `passwd` afterward,
persisting across future rebuilds. Reading NixOS's actual activation
script (`update-users-groups.pl`) confirmed `mutableUsers = false`
unconditionally re-locks/reasserts the configured password on *every*
activation, regardless of `hashedPasswordFile`, `userborn`, or any custom
activation script workaround — there's no way to get both "out-of-repo
secret" and "user-changeable" under `mutableUsers = false`.
`initialHashedPassword` under `mutableUsers = true` is applied exactly
once, at account creation; after that, whatever the user sets via `passwd`
is permanently theirs. The tradeoff: this value can't be used to
force-rotate a password later by editing config — once the account exists,
it's inert for that account.

The three hashes (`BEARDEDTEK_INITIAL_HASH`, `DYOUNG_INITIAL_HASH`,
`ROOT_INITIAL_HASH`) come from `secrets/initial-passwords.env` via
`builtins.getEnv` in `flake.nix`'s `specialArgs` — never committed, and
only readable under impure evaluation. See `docs/DEPLOYMENT.md`.

`beardedtek`'s real SSH public key is likewise never committed — delivered
straight to `/home/beardedtek/.ssh/authorized_keys` via
`nixos-anywhere --extra-files`, landing on the real `rust/home` dataset
(not tmpfs), so it persists without needing an `environment.persistence`
entry.

## Network and firewall model

Every module that opens firewall ports scopes them per-interface, never a
blanket `networking.firewall.allowedTCPPorts`:

- `config.mySystem.lanInterface` (`modules/common.nix`) — the physical LAN
  NIC, single source of truth used by `samba.nix`, `nfs.nix`, and
  `common.nix` itself (for SSH).
- `"nebula1"` — the Nebula mesh interface, opened alongside LAN for every
  service that should also be reachable remotely over the mesh.

SSH: key-only (`PasswordAuthentication = false`), root login disabled
(`PermitRootLogin = "no"`) — meaning any `nixos-rebuild --target-host`
push has to authenticate as `beardedtek` (or `dyoung`) with `--sudo`, not
`root@`. `boot.initrd.systemd.emergencyAccess = true` grants an
unauthenticated shell in the *initrd* specifically (a separate, minimal
environment from the real system, without root's password) — for
debugging an early-boot mount failure without needing physical installer
media at that stage. This is not a bypass of the real system's
authentication, only the initrd's.

NFS is NFSv4-only (`services.nfs.settings.nfsd.vers3/vers2 = false`) and
auto-detects its own LAN export subnet at every `nfs-server` start (see
`modules/nfs.nix`'s `preStart` script) rather than hardcoding a CIDR —
always exports to the Nebula mesh (`10.100.0.0/24`, static) plus whatever
subnet is currently live on `mySystem.lanInterface`. Worth knowing: this
means NFS opens to *whatever network the box is plugged into* on that
interface with no manual review step — acceptable for a home LAN that
doesn't change, worth reconsidering if that assumption ever changes.

## Services

Native NixOS services wherever a solid module exists, containers avoided
entirely (no docker/podman anywhere in this config) — everything runs as a
directly-managed systemd unit.

| Service | Module | Local port | Firewall scope |
|---|---|---|---|
| Samba | `modules/samba.nix` | 445 | LAN + nebula1 |
| NFSv4 | `modules/nfs.nix` | 2049 | LAN (auto-detected subnet) + nebula1 |
| Jellyfin | `modules/media-stack.nix` | 8096 | open |
| Sonarr | `modules/media-stack.nix` | 8989 | open |
| Radarr | `modules/media-stack.nix` | 7878 | open |
| Jackett | `modules/media-stack.nix` | 9117 | open |
| Seerr (Jellyseerr) | `modules/media-stack.nix` | 5055 | open |
| qBittorrent | `modules/media-stack.nix` | 8080 (webUI) | open |
| Nebula | `modules/nebula.nix` | 4242/udp | — (this *is* the mesh) |
| Traefik (proxy) | `modules/traefik.nix` | 80/443/8099 | nebula1 only |

### Jellyfin

`hardware.graphics.extraPackages = [ pkgs.intel-media-driver ]` — the
**iHD** driver specifically. The older `vaapiIntel`/i965 driver does not
support N-series (Jasper Lake/Alder Lake-N) hardware, so hardware
transcode would silently fall back to software without this. After
deploy, VAAPI still needs to be enabled by hand in Jellyfin's own
Dashboard → Playback settings against the correct `/dev/dri/renderD*`
device — that's app config, not a Nix option.

`cacheDir` is redirected to `/var/lib/jellyfin/cache` instead of the
module's default `/var/cache/jellyfin`, which lives on the 2GB tmpfs root.
See `docs/TROUBLESHOOTING.md` — Jellyfin refuses to start at all if its
cache-dir free-space check fails, and transcode/image cache can easily
exceed what's safe to keep in RAM anyway.

### Seerr (Jellyseerr)

Jellyseerr's upstream project renamed to "Seerr" and merged with Overseerr;
nixpkgs 26.05 ships a native `services.seerr` module (auto-aliased from
the old `services.jellyseerr` name). The module's `DynamicUser = true`
default is overridden to a fixed `seerr` system user — see
`docs/TROUBLESHOOTING.md` for why that combination breaks under
impermanence specifically.

### Shared `/rust/media` and `/rust/data` access

Jellyfin, Sonarr, Radarr, qBittorrent, and Seerr all need to share access to
the media library (`/rust/media`) and/or the downloads directory
(`/rust/data` — where qBittorrent writes completed downloads and
Sonarr/Radarr import from), but each runs as its own dedicated system
user/group (`jellyfin`, `sonarr`, `radarr`, `qbittorrent`, `seerr`). Rather
than loosening either path to world-readable/writable, all five users are
added to a shared `mediagroup` group (`users.groups.mediagroup` in
`modules/media-stack.nix`), and both datasets' ownership/permissions are
set once so that group can read/write them. Since both already hold real,
existing data (not a fresh service state dir Nix creates itself), that
one-time ownership fix is a manual operational step, not a NixOS activation
script — see `docs/DEPLOYMENT.md`.

### qBittorrent

`services.qbittorrent`, default `webuiPort` (8080), state dir
`/var/lib/qBittorrent` (capital Q — matches the module's actual default
`profileDir` exactly; this has to match verbatim in the persistence
`directories` list).

### Traefik

Reverse-proxies every web service behind `<name>-young.nebula.beardedtek.com`,
reachable only over the Nebula mesh — every entrypoint in
`modules/traefik.nix` binds specifically to `10.100.0.17` (young's own
`nebula1` address), never `0.0.0.0`. Translated from the user's existing
`traefik:v3` docker-compose setup: since there's no docker socket/provider
here, dynamic routing is declared directly via `dynamicConfigOptions`
(file provider, wired automatically by the `services.traefik` module)
instead of container labels.

- **Cert**: a single wildcard cert for `*.nebula.beardedtek.com` via
  DNS-01 (Linode provider), configured once at the `https` entrypoint's
  default TLS options (`entryPoints.https.http.tls.domains`) rather than
  the original compose's dummy "wildcard" router hack — functionally
  equivalent, applies to every router on that entrypoint automatically.
- **Secret**: `LINODE_TOKEN` comes from `/etc/traefik/traefik.env`
  (`environmentFiles`), an out-of-repo secret delivered the same way as
  Nebula's config — see `docs/DEPLOYMENT.md`'s secrets table. Traefik's
  Linode DNS provider reads it straight from the process environment; no
  templating needed in the static config.
- **Dashboard port is 8099, not Traefik's default 8080** — 8080 is
  qBittorrent's default webUI port, and both would otherwise try to bind
  the same port on the same Nebula IP. 8099 also matches the original
  compose's external host-port mapping, so it's the same port already
  familiar from that setup.
- **Domain naming convention**: `<service>-young.nebula.beardedtek.com`
  for every proxied service (the `-young` suffix disambiguates this host
  if another machine is ever added to the mesh later). Traefik itself
  doesn't create DNS records — `*.nebula.beardedtek.com` needs to actually
  resolve to `10.100.0.17` for mesh clients, managed separately wherever
  the rest of `beardedtek.com`'s DNS lives.

## Deploying and updating

Full procedure in `docs/DEPLOYMENT.md`. The short version for routine
updates once the box is already installed: `nixos-rebuild switch --flake
.#young --target-host beardedtek@<ip> --sudo --impure` from a machine with
`secrets/initial-passwords.env` sourced. Several non-obvious requirements
for that command to work at all are documented in
`docs/TROUBLESHOOTING.md`'s "Remote deployment" section — trusted-users,
sudo's environment stripping, and the `--impure`/`--option pure-eval
false` split between `nixos-rebuild` and `nixos-anywhere`.
