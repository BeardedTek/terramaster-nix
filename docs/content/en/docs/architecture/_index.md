---
title: Architecture
linkTitle: Architecture
weight: 50
description: Design rationale and internals for anyone maintaining or extending the flake itself.
---

Reference material: what each piece is for and why it's built this way,
plus the failure modes hit (and fixed) building and operating this
system. This isn't needed to just install and use a box — see
[Introduction](/docs/introduction/), [Installation](/docs/installation/),
and [Usage](/docs/usage/) for that. This doc is for anyone maintaining or
extending the flake itself.

## `variables.nix`

The one file to edit for host-level tuning — hostname, contact info,
which service groups/services are enabled, and which hardware profile
this instance uses. Imported two ways by `flake.nix`: once as a plain
`import` (evaluated *before* `nixosSystem` is even called, purely to read
`mySystem.manufacturer`/`mySystem.model` — see below) and once as an
ordinary module in the `modules` list, same as any file under `modules/`.
Both reads see the exact same file, so there's no risk of the two
disagreeing.

- **`mySystem.manufacturer` / `mySystem.model`**: selects which
  `hosts/<manufacturer>/<model>/` directory supplies this instance's
  hardware profile (`disko.nix` — disk partitioning — and
  `configuration.nix` — filesystems, `hostId`, persistence list).
  `flake.nix` builds the path as
  `./hosts + "/${manufacturer}/${model}"` and imports
  `<that>/disko.nix` and `<that>/configuration.nix` directly, instead of
  those paths being hardcoded in `flake.nix` itself. A typo or nonexistent
  pair fails loudly at eval time (`path does not exist`), pointing at the
  exact directory that wasn't found.
  Currently `"terramaster"` / `"young"`, pointing at
  `hosts/terramaster/young/` — the real, deployed configuration for this
  specific physical box (its actual `hostId`, its actual USB drive's
  `by-id` path, both already filled in, not placeholders). The second
  path segment doesn't have to be a hardware model name; it's just
  whichever directory identifies *this instance*. `hosts/terramaster/`
  also has `f4-245/`, a separate, generic **template** for provisioning a
  *different, blank* TerraMaster F4-245 — `CHANGEME` placeholders instead
  of real device paths, no real `hostId`, and (see "Automated ZFS pool
  creation" below) a from-scratch ZFS pool instead of the
  manually-imported one `young` already has. Nothing in `variables.nix`
  points at `f4-245/` today; it exists to be copied to a new
  `hosts/<manufacturer>/<new-instance-name>/` and filled in when a second
  box shows up, not to be run as-is.
  **Not yet built**: multiple *simultaneous* `nixosConfigurations` in this
  one flake (today there's still only `nixosConfigurations.young`). Adding
  a genuinely second NAS alongside this one would mean giving it its own
  variables file and its own `nixosConfigurations.<name>` entry in
  `flake.nix`, each pointing at whichever `hosts/<manufacturer>/<model>/`
  fits its hardware — this change makes that a small, mechanical addition
  rather than a restructuring, but doesn't do it preemptively.
- **`networking.hostName`**: the single source of truth for the box's
  name. `modules/traefik.nix`, `modules/frigate.nix`, and
  `modules/samba.nix` all read `config.networking.hostName` rather than
  hardcoding it, so changing it here actually renames every proxied
  domain (`<service>.<hostname>.beardedtek.com`,
  `<service>-<hostname>.nebula.beardedtek.com`), Frigate's own vhost, and
  the Samba server string/NetBIOS name/workgroup, consistently. It does
  **not** touch the ZFS-import-critical `networking.hostId` (a separate,
  arbitrary identifier — see "ZFS dataset map" below) or anything in the
  Hugo dashboard's static prose (`dashboard/content/*.md`'s Samba/NFS
  pages still say "young" and list fixed IPs directly, since those are
  plain markdown, not templated).
- **`mySystem.contactInfo`**: unchanged from before, just relocated here.
- **`mySystem.features`**: enable/disable each service, declared in
  `modules/common.nix`'s options and consumed by each service's own
  module. Two levels: a **group** toggle (`homeAssistant.enable`,
  `mediaAcquisition.enable`) that fully turns off everything in that
  group, and **per-service** toggles underneath that only matter while
  their group is on:
  ```nix
  mySystem.features = {
    jellyfin.enable = true;
    frigate.enable = true;
    minio.enable = false; # S3-compatible object storage, off by default
    filebrowser.enable = false; # web file browser over /rust/media and /rust/data
    homeAssistant = {
      enable = true;       # Home Assistant + its Mosquitto broker + its Samba share
      zwave.enable = false; # no dongle attached yet
      hacs.enable = true;
    };
    mediaAcquisition = {
      enable = true;        # Seerr, Radarr, Sonarr, Jackett, qBittorrent
      seerr.enable = true;
      radarr.enable = true;
      sonarr.enable = true;
      jackett.enable = true;
      qbittorrent.enable = true;
    };
  };
  ```
  Turning a service off is fully inert, not just "the process doesn't
  run": its Traefik routers/backend service disappear from
  `modules/traefik.nix`'s dynamic config, it drops out of
  `mySystem.serviceBackends` (so `modules/dashboard.nix`'s metrics script
  stops polling its port and its dashboard tile hides itself — see
  `dashboard/content/services.md`'s `applyStatus()`), and its per-service
  firewall rule (declared in each service's own module) never gets added.
  Disabling the whole `homeAssistant` group also drops the Samba `hass`
  share (`modules/samba.nix`) and the Mosquitto broker, since both exist
  only to support it. Persistence directories
  (`environment.persistence."/persist".directories` in
  `hosts/terramaster/young/configuration.nix`) are left listed regardless of any
  toggle — harmless if the directory never gets created, and one less
  thing to keep in sync by hand.
  Every module implements this the same way: gate the whole file's
  `config` under `lib.mkIf <group>.enable`, then `lib.mkMerge` in
  sub-toggle-specific blocks under `lib.mkIf <group>.<sub>.enable` for
  anything that's separately switchable (`modules/home-assistant.nix`'s
  HACS install service is the clearest example — see its `mkMerge` list).

## Hardware

TerraMaster F4-245: 4-bay NAS, Intel N-series CPU (QuickSync-capable, iHD
driver generation), 16GB DDR4-3200 RAM, 4x 6TB HDDs, 256GB drive in the
internal USB slot used as the boot/system drive.

## Storage design

### The `rust` pool is pre-existing and untouched by disko

`rust` (RAIDZ1 across the 4 HDDs) already existed before this flake, with
data already on it. `hosts/terramaster/young/disko.nix` only ever partitions the
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
`hosts/terramaster/young/configuration.nix`) bind-mounts specific paths from `/persist`
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
`hosts/terramaster/young/configuration.nix`), not just its children — must be
`mountpoint=legacy`. See the [Failure modes](#failure-modes-hit-during-development)
for the exact failure signatures this produces when missed, and the
[nixos-anywhere installation guide](/docs/installation/nixos-anywhere/) for the one-time `zfs set`
commands.

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
| `rust/minio` | `/rust/minio` | new — MinIO's data/config, see the "MinIO" section below |

All mounted `fsType = "zfs"`, all `mountpoint=legacy` on the pool side.

### Automated ZFS pool creation for a new, blank NAS

`young`'s `rust` pool predates this flake and is deliberately never touched
by disko (previous section) — but that rule exists specifically because
`rust` already had real data on it. A *different*, genuinely blank NAS
doesn't have that constraint, and for that case `lib/zfs-pool.nix` can
have disko create the pool and every dataset from scratch, instead of
requiring a manual `zpool create` + `zfs create` walkthrough before every
new install.

`lib/zfs-pool.nix` is a plain function, not a NixOS module — call it from
a host's `disko.nix` with the pool's shape:

```nix
{ lib, ... }:
import ../../../lib/zfs-pool.nix {
  inherit lib;
  poolName = "rust";
  raidLevel = "raidz1"; # or "mirror", "raidz2", ""  (stripe)
  disks = [
    "/dev/disk/by-id/..."
    "/dev/disk/by-id/..."
    # one entry per member disk
  ];
  datasets = [
    { name = "nix"; mountpoint = "/nix"; }
    { name = "persist"; mountpoint = "/persist"; }
    { name = "home"; mountpoint = "/home"; }
    { name = "media"; mountpoint = "/rust/media"; }
    { name = "data"; mountpoint = "/rust/data"; }
  ];
}
```

It returns a `disko.devices` fragment: one `disk.<n>` entry per drive (a
single GPT partition, `content.type = "zfs"`, feeding into the named
pool) and one `zpool.<poolName>` entry with the given topology, `ashift =
"12"`, and each dataset set to `options.mountpoint = "legacy"` — the same
hard-won "every dataset must be legacy-mounted" rule from the previous
section, just applied automatically instead of by hand. disko's own
module then derives real `fileSystems.*` entries from this — `/nix`,
`/persist`, `/home`, `/rust/media`, `/rust/data`, and `/rust` itself —
so, unlike `young`'s `configuration.nix`, a host using this doesn't
hand-write any `fileSystems.*` entries for its pool at all. Verified with
a standalone `nix eval` against placeholder disk paths: produces exactly
that `fileSystems` set, correct `mountpoint=legacy` on every dataset.

`hosts/terramaster/f4-245/` is this pattern's concrete template — see the
`variables.nix` section above for how it relates to `hosts/terramaster/young/`.

**This is unconditionally destructive, same as every other disko-managed
device in this repo (the USB boot drive included).** disko formats
whatever it's told to, every time it runs — there's no "only if the pool
doesn't already exist yet" check. Only ever point `disks` at drives you
know are blank. This is *why* `young`'s own pool is handled the opposite
way (manually pre-created, manually imported, never declared to disko) —
automating creation is only safe for hardware that doesn't have anything
on it yet.

**Dataset names and `poolName` aren't fully free-form in this repo**:
`modules/media-stack.nix`, `modules/samba.nix`, and `modules/nfs.nix` all
hardcode absolute paths like `/rust/media` and `/rust/data` rather than
reading the pool name from anywhere — so a new host that wants to reuse
those modules as-is needs `poolName = "rust";` and the same `media`/`data`
mountpoints shown above. Parameterizing those modules' paths would be a
separate, larger change, not done here.

## What's persisted, and why

`environment.persistence."/persist"` in `hosts/terramaster/young/configuration.nix`
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
  directory. See the [Failure modes](#failure-modes-hit-during-development) for why
  that distinction matters.

## Users and passwords

Accounts are data, not code: `variables.nix` lists who exists —

```nix
mySystem.users = [
  { name = "beardedtek"; wheel = true; }
  { name = "dyoung"; wheel = true; }
];
```

— and `modules/users.nix` (implementing `options.mySystem.users` from
`modules/common.nix`) turns that list into real `users.users.*` entries,
`root` included implicitly (not part of the list, always created).
Adding, removing, or changing who has `wheel` (sudo, password-required via
`security.sudo.wheelNeedsPassword = true`, also set in `modules/users.nix`)
is a `variables.nix` edit, not a `hosts/*/configuration.nix` one. Neither
account has Samba access extended to `root`.

`users.mutableUsers = true` plus `initialHashedPassword` per account is a
deliberate, specific choice, not the default pattern most NixOS configs
use. The requirement was: passwords provided as out-of-repo secrets, but
genuinely self-service changeable via `passwd` afterward, persisting
across future rebuilds. Reading NixOS's actual activation script
(`update-users-groups.pl`) confirmed `mutableUsers = false`
unconditionally re-locks/reasserts the configured password on *every*
activation, regardless of `hashedPasswordFile`, `userborn`, or any custom
activation script workaround — there's no way to get both "out-of-repo
secret" and "user-changeable" under `mutableUsers = false`.
`initialHashedPassword` under `mutableUsers = true` is applied exactly
once, at account creation; after that, whatever the user sets via `passwd`
is permanently theirs. The tradeoff: this value can't be used to
force-rotate a password later by editing config — once the account exists,
it's inert for that account.

Each account's hash comes from the environment variable
`<NAME_UPPERCASE>_INITIAL_HASH` (`modules/users.nix` reads it via
`builtins.getEnv`, deriving the variable name from `mySystem.users`
automatically — adding a user to the list needs no matching edit anywhere
else) — sourced from `secrets/initial-passwords.env`, never committed, and
only readable under impure evaluation. `modules/users.nix` also generates
one assertion per account (including `root`) that fails the build early
with a clear message if its hash is empty. See the
[nixos-anywhere installation guide](/docs/installation/nixos-anywhere/).

`beardedtek`'s real SSH public key is likewise never committed — delivered
straight to `/home/beardedtek/.ssh/authorized_keys` via
`nixos-anywhere --extra-files`, landing on the real `rust/home` dataset
(not tmpfs), so it persists without needing an `environment.persistence`
entry.

### Unix/PAM login against LLDAP

`modules/unix-ldap-login.nix` (gated on `mySystem.features.sso.enable`, same
flag the LLDAP/Authelia SSO rollout uses elsewhere) adds the same LLDAP
directory as an *additional* authentication source for local console login
and `sudo`/`su`, via `users.ldap.loginPam` and nslcd (`users.ldap.daemon.enable`,
isolating the LDAP bind password to nslcd's own process rather than every
PAM-consuming process reading it directly). It does not replace anything:
local accounts from `mySystem.users` above keep their own password hashes,
and NixOS's default PAM rule stack (`nixos/modules/security/pam.nix`) puts
`pam_unix` ahead of `pam_ldap`, both `sufficient` — local logins keep
working exactly as before even if LLDAP is unreachable. `nsswitch` stays
off: every LLDAP account already has a matching local Unix account (LLDAP
mirrors `mySystem.users` exactly, see below), so there's no "LDAP-only"
identity for NSS to resolve yet. SSH itself is untouched — it's key-only
(`mySystem.security.sshPasswordAuth` defaults to `false`), so PAM auth is
never consulted there regardless of this module.

Like every other service that needs to look up *someone else's* LLDAP
entry (Authelia, the dashboard's own login, Jellyfin's LDAP plugin), this
uses a dedicated `uid=unix-login,ou=people,...` bind account in LLDAP's
built-in `lldap_strict_readonly` group — a plain bind can only ever see its
own entry, and nslcd needs to search for a user's DN by username before
re-binding as them.

## Network and firewall model

Every module that opens firewall ports scopes them per-interface, never a
blanket `networking.firewall.allowedTCPPorts`:

- `config.mySystem.lanInterface` (`modules/common.nix`) — the physical LAN
  NIC, single source of truth used by `samba.nix`, `nfs.nix`, and
  `common.nix` itself (for SSH).
- `"nebula1"` — the Nebula mesh interface, opened alongside LAN for every
  service that should also be reachable remotely over the mesh.

SSH: key-only by default (`PasswordAuthentication` follows
`mySystem.security.sshPasswordAuth`, `false` unless a host's
`variables.nix` opts in — `young` doesn't), root login disabled
unconditionally (`PermitRootLogin = "no"`). The [ISO installer guide](/docs/installation/iso/)'s
Secrets step can set `mySystem.security.sshPasswordAuth = true;` for a
new instance provisioned without an SSH key on hand, but it's off
everywhere else — meaning any `nixos-rebuild --target-host`
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
| Traefik (proxy) | `modules/traefik.nix` | 80/443/8099/8090 | LAN + nebula1 (8090: LAN only) |
| Dashboard (nginx) | `modules/dashboard.nix` | 8097 | LAN + nebula1 |
| Frigate (via its own nginx vhost) | `modules/frigate.nix` | 8098 | LAN + nebula1 |
| Home Assistant | `modules/home-assistant.nix` | 8123 | LAN + nebula1 |
| Mosquitto (MQTT) | `modules/home-assistant.nix` | 1883 | LAN + nebula1 |
| MinIO (S3 API) | `modules/minio.nix` | 9000 | LAN + nebula1 |
| MinIO (console) | `modules/minio.nix` | 9001 | LAN + nebula1 |
| FileBrowser (Quantum) | `modules/filebrowser.nix` | 8095 | LAN + nebula1 |
| LLDAP | `modules/lldap.nix` | 3890 (LDAP) / 17170 (admin UI) | LAN only |
| Authelia | `modules/authelia.nix` | 9091 | open |

### LLDAP

`modules/lldap.nix` — the directory every login on this box ultimately
checks against (gated on `mySystem.features.sso.enable`). Deliberately
**LAN-only**, never routed through Traefik or exposed on `nebula1`: it's
the identity source of truth everything else (Authelia, the dashboard's
own login, Unix/PAM login) depends on, so it shouldn't sit behind the
thing that depends on it, and should stay reachable even if something
downstream of it breaks.

`mySystem.users` is the actual source of truth for LDAP accounts, not
just Unix ones — a `lldap-provision-users` systemd oneshot (re-run on
every activation) reconciles LLDAP against it using LLDAP's own official
`bootstrap.sh` script, pinned to the exact commit matching nixpkgs'
`lldap` package version. `wheel = true` in `mySystem.users` maps to
LLDAP's `admins` group. Every other module that needs to look up
*someone else's* LDAP entry (Authelia, the dashboard's login, Jellyfin's
LDAP plugin, `unix-ldap-login`) provisions its own dedicated bind account
in LLDAP's built-in `lldap_strict_readonly` group, following the exact
same pinned-`bootstrap.sh` pattern — confirmed repeatedly that a plain
LDAP bind can only ever see its own entry, so any service that needs to
search or read *other* users' entries needs one of these dedicated
accounts, not just its own user's bind.

### Authelia

`modules/authelia.nix` — SSO/forward-auth/OIDC provider sitting in front
of every service that doesn't have native LDAP/OIDC support of its own
(gated on `mySystem.features.sso.authelia.enable`, LDAP-backed against
LLDAP on `127.0.0.1:3890`). The one "hot-pluggable" table this design is
built around:

```nix
candidateProtectedServices = {
  sonarr = { enable = true; policy = "one_factor"; };
  # ...one line per gate-only service...
};
```

filtered down to `protectedServices` and exposed as
`mySystem.sso.protectedServices` — the same "one file computes, another
consumes" shape `mySystem.serviceBackends` already established between
`modules/traefik.nix` and `modules/dashboard.nix`. `modules/traefik.nix`
reads this table to decide which routers get the `authelia` ForwardAuth
middleware attached; adding a newly-protected service later is one line
here plus that service's normal Traefik backend entry, no hand-written
Authelia YAML.

A second table, `candidateOidcClients`, covers services with real native
OIDC support instead of a plain forward-auth gate (MinIO console,
FileBrowser, Home Assistant via a HACS-installed OIDC component) — each
gets a real registered OIDC client, plaintext secrets delivered
out-of-repo the same way as every other secret in this config.

**The dashboard's own login deliberately does not route through
Authelia** — Authelia's session cookie is scoped to a specific domain,
and browsers never send a domain-scoped cookie to a raw-IP request. Since
the dashboard is meant to also be reachable by bare IP if DNS/Traefik
ever breaks, it has its own independent LDAP-bind login instead (see
`modules/dashboard-login.nix`) with a host-only session cookie that works
correctly regardless of which exact host/IP was used to reach it.

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
See the [Failure modes](#failure-modes-hit-during-development) — Jellyfin refuses
to start at all if its cache-dir free-space check fails, and
transcode/image cache can easily exceed what's safe to keep in RAM
anyway.

### Seerr (Jellyseerr)

Jellyseerr's upstream project renamed to "Seerr" and merged with Overseerr;
nixpkgs 26.05 ships a native `services.seerr` module (auto-aliased from
the old `services.jellyseerr` name). The module's `DynamicUser = true`
default is overridden to a fixed `seerr` system user — see the
[Failure modes](#failure-modes-hit-during-development) for why that combination
breaks under impermanence specifically.

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
script — see the [nixos-anywhere installation guide](/docs/installation/nixos-anywhere/).

### Dashboard

A small Hugo-built static site (`dashboard/` at the repo root) served by
nginx on port 8097, proxied by Traefik at `young.nebula.beardedtek.com`
(mesh) and `young.beardedtek.com` (LAN) — the box's own landing page,
separate from the `<name>-young`/`<name>.young` pattern every other
backend uses.

- **Theme**: styled to match beardedtek.com, using vendored (pre-built,
  not recompiled) CSS/JS bundles from
  [flowbite-beardedtek.com](https://github.com/beardedtek/flowbite-beardedtek.com)
  under `dashboard/static/`. Deliberately **not** running that repo's own
  npm/webpack/Tailwind build pipeline here — vendoring the already-compiled
  output keeps the Nix derivation a single lightweight `hugo` invocation
  (no Node toolchain at all), matching the "very minimal overhead" the
  live-metrics requirement was built around. Tradeoff: any Tailwind
  utility class not already present in the vendored CSS won't be styled —
  layouts here deliberately stick to common Flowbite component classes
  known to already be in that build.
- **Pages**: Home (live metrics), Services (button grid to every proxied
  backend), Samba, NFS, and Troubleshooting — content lives as plain
  Markdown/HTML under `dashboard/content/` (`unsafe = true` in
  `hugo.toml`'s goldmark config allows raw HTML directly in the Markdown,
  avoiding a pile of one-off Hugo layout templates for simple pages).
- **Live metrics, without a metrics stack**: `systemd.timers.dashboard-metrics`
  regenerates `/var/lib/dashboard/metrics.json` every 30s via a single `jq`
  + `df`/`/proc` shell script (`modules/dashboard.nix`) — no Prometheus,
  no historical data, current readings only, exactly as asked for. The
  dashboard homepage's `dashboard.js` just does a client-side `fetch()` of
  that file on the same 30s interval. Never added to
  `environment.persistence` — it fully regenerates within 30s of every
  boot, so there's nothing worth carrying across the tmpfs root, and one
  less path to get the impermanence-bind-mount-timing bug wrong on (see
  the [Failure modes](#failure-modes-hit-during-development)).
- **Services page links are domain-aware at runtime**: a small inline
  script checks `location.hostname` for `.nebula.` and builds each
  service's link as either the Nebula or LAN domain accordingly — so the
  same static HTML works correctly whichever network you're actually
  browsing from, without server-side logic.
- **Per-service up/down status**: the same `dashboard-metrics` run above
  also does a plain TCP connect check against each backend's local port
  and includes the result in `metrics.json` — not a separate polling
  system. The Services page greys out (and badges "DOWN") any tile whose
  service isn't reachable. The port list itself isn't duplicated between
  modules: `options.mySystem.serviceBackends` (`modules/common.nix`) is
  set once in `modules/traefik.nix` (where the name→port map already
  existed for routing) and read back in `modules/dashboard.nix` — same
  pattern as `mySystem.lanInterface`.
- **Admin contact info** (`options.mySystem.contactInfo`, `modules/common.nix`):
  a list of `{ label, email, phone }` entries, set in `variables.nix`
  rather than hardcoded into the Hugo content.
  `modules/dashboard.nix` serializes it to `data/contact.json`
  and copies it into the Hugo source tree at build time (Hugo auto-loads
  any `data/*.json` as `.Site.Data.contact`), read by
  `dashboard/layouts/partials/contact-info.html` — shared by the footer
  (every page) and the Help page's `contact` shortcode, so there's
  one source of truth instead of duplicating the list in two templates.

### qBittorrent

`services.qbittorrent`, default `webuiPort` (8080), state dir
`/var/lib/qBittorrent` (capital Q — matches the module's actual default
`profileDir` exactly; this has to match verbatim in the persistence
`directories` list).

### Frigate

`modules/frigate.nix` — NVR/object detection. Deliberately minimal for
now: `settings.cameras = { }` (no cameras yet) and a single CPU detector
(`detectors.cpu1.type = "cpu"`), just enough to confirm the service comes
up correctly. A Coral USB TPU is planned but not physically attached yet;
swap the CPU detector for an `edgetpu` one once it is.

Frigate doesn't fit the generic `backends`-port pattern the same way as
everything else here:

- **It ships its own full nginx reverse-proxy vhost** (`services.frigate`
  sets up `services.nginx.virtualHosts.${hostname}` itself, including its
  own `/auth` `auth_request` flow, go2rtc/vod/jsmpeg proxying). Left at
  its defaults, that vhost binds the standard `:80` on every interface —
  which would fight Traefik for the same port, since Traefik is the sole
  owner of `:80`/`:443` everywhere else in this config. `modules/frigate.nix`
  rebinds that same vhost to `127.0.0.1:8098` and adds the Nebula domain
  as a `serverAlias` on the same vhost (rather than a second vhost), so it
  fits the same "Traefik → 127.0.0.1:&lt;port&gt;" shape as every other
  backend despite the nginx layer in between.
- **Auth is Frigate's own built-in login, unchanged** — no attempt to
  unify it with system accounts. Frigate has no PAM/Linux-account
  integration at all; its only alternative is "proxy" mode, which
  delegates trust to an *already-authenticating* upstream (Authelia,
  Authentik, oauth2-proxy, traefik-forward-auth) rather than checking any
  password itself — none of those check Linux system accounts either,
  so it wouldn't actually have been "the same users as the system" in any
  real sense. Genuinely reusing system accounts would require nginx's PAM
  auth module (`pkgs.nginxModules.pam` exists) validating credentials and
  injecting trusted headers into Frigate's proxy mode — a materially
  bigger integration (overriding several of Frigate's own generated nginx
  locations, coupled to that module's internals) that wasn't taken on
  here. First login uses the admin account Frigate auto-generates and
  prints to its own log on first start (`journalctl -u frigate`),
  manageable afterward under its own Settings → Users.
- **Frigate's config gets validated at build time** — `checkConfig`
  (default `true`) runs Frigate's own `python -m frigate --validate-config`
  against the generated YAML as part of the Nix build, the same kind of
  safety net `writeShellApplication`'s shellcheck integration provides
  elsewhere in this repo. Confirmed directly: an empty `cameras = { }` is
  accepted by Frigate's own validator, not just by the NixOS module.

### Home Assistant

`modules/home-assistant.nix` — `services.home-assistant`, reachable at
`hass.young.beardedtek.com` / `hass-young.nebula.beardedtek.com` via the
generic `backends`-map pattern (no special-casing needed, unlike Frigate
or qBittorrent — HA doesn't validate the Host header itself). Native
NixOS services stand in for what would be HAOS/Supervisor "add-ons" on a
normal HA install — HACS (fetched directly, no nixpkgs package exists),
Z-Wave JS (`services.zwave-js`, currently disabled — no dongle attached
yet), Mosquitto (`services.mosquitto`), and a Samba share for the config
directory. See [Usage → Home Assistant](/docs/usage/services/home-assistant/)
for the user-facing side of HACS activation and Z-Wave enablement.

### MinIO

`modules/minio.nix` — S3-compatible object storage, off by default
(`mySystem.features.minio.enable = false;`). Two backends registered with
Traefik via the generic `backends`-map pattern: `minio` (the S3 API,
port 9000) and `minio-console` (the web console, port 9001), each
getting its own pair of routers/domains the same way every other service
here does — no special-casing needed, unlike Frigate or qBittorrent.

- **Package**: nixpkgs' own `pkgs.minio` predates upstream `minio/minio`
  archiving its GitHub repo in 2025 (after removing most of the open
  source Console/community edition in favor of their commercial AIStor
  product), so it isn't a reliable source of current releases. This repo
  builds its own package (`pkgs/minio.nix`) directly from
  [pgsty/minio](https://github.com/pgsty/minio) — a fork maintained by the
  Pigsty project (which depends on MinIO for its own Postgres
  backup/object-storage stack) that keeps publishing releases from the
  same source. The upstream release is a statically-linked Go binary, so
  the package is just a `fetchurl` + install, no build step and no
  `autoPatchelfHook` needed. Bump the pinned release tag/version/hash in
  that file to update.
- **Reuses nixpkgs' `services.minio` module** for everything except the
  package itself (`services.minio.package = pkgs.callPackage
  ../pkgs/minio.nix { };`) — systemd hardening, the `minio` user/group,
  and `tmpfiles` rules all come from nixpkgs, unmodified.
- **Root credentials**: out-of-repo, same pattern as Traefik's
  `LINODE_TOKEN` — `rootCredentialsFile = "/etc/minio/minio.env";`, an
  `EnvironmentFile=` with `MINIO_ROOT_USER`/`MINIO_ROOT_PASSWORD`. See
  `secrets/extra-files/persist/etc/minio/minio.env.example` and the
  [nixos-anywhere installation guide](/docs/installation/nixos-anywhere/)'s secrets section. Missing the file is
  a clean no-start (nixpkgs' module sets `ConditionPathExists` on it), not
  a crash loop — same posture as Z-Wave without a dongle.
- **Storage**: a dedicated `rust/minio` dataset (`mountpoint=legacy`,
  same rule as every other dataset — see the ZFS dataset map above),
  mounted at `/rust/minio` — `dataDir = [ "/rust/minio/data" ];` and
  `configDir = "/rust/minio/config";`, overriding the module's own
  `/var/lib/minio` default. Two reasons, one conceptual and one a real
  bug hit on first deploy:
  - Object storage is bulk data — the same category as `rust/media` and
    `rust/data` — not small app config/state like every other
    `/var/lib/<name>` entry in `environment.persistence`.
  - **The `/var/lib/minio` default failed outright the first time this
    was deployed**: `minio.service` exited immediately with `"file
    access denied"`. Cause: the exact "freshly-created persistence
    bind-mount gets the wrong ownership" race the
    [Failure modes](#failure-modes-hit-during-development) already documents for
    qBittorrent and Home Assistant, just under a third mechanism —
    nixpkgs' `services.minio` module creates `dataDir`/`configDir` via
    `systemd.tmpfiles.rules`, and on the same activation that both
    introduces those rules *and* creates the brand-new `/persist`
    bind-mount for `/var/lib/minio`, the ordering between the two isn't
    guaranteed. A real ZFS `fileSystems` entry doesn't have this
    failure mode at all — it's mounted directly at boot, no bind-mount
    indirection to race against. `systemd.services.minio.unitConfig.RequiresMountsFor
    = [ "/rust/minio" ];` covers the (separate, smaller) risk of the
    service starting before that mount is up.
  - Not part of `disko.nix` for `young` (created manually, same as
    `rust/nix`/`rust/persist` were — see the
    [nixos-anywhere installation guide](/docs/installation/nixos-anywhere/)); `hosts/terramaster/f4-245/disko.nix`'s
    `zfs-pool.nix` call includes it for future from-scratch installs.
    The installer wizard's "adopt an existing pool" path doesn't
    currently offer creating this dataset — a known gap, not yet hit
    since MinIO defaults off.

### FileBrowser

`modules/filebrowser.nix` — a web file browser over the existing
`/rust/media` and `/rust/data` datasets, off by default
(`mySystem.features.filebrowser.enable = false;`). Registered with
Traefik as `files` (not `filebrowser`) — deliberately named after what a
user is trying to do, not the specific software providing it, since the
underlying tool is exactly the kind of thing that could get swapped out
later without the URL people actually bookmark needing to change.

- **[FileBrowser Quantum](https://github.com/gtsteffaniak/filebrowser)**
  (`gtsteffaniak/filebrowser`, package name `filebrowser-quantum` in
  nixpkgs), not the older `filebrowser/filebrowser` project nixpkgs also
  ships (`pkgs.filebrowser`, with its own `services.filebrowser` module).
  Chosen specifically because it supports multiple independently-named
  *sources* — classic FileBrowser only serves one `root` directory, which
  would have meant either exposing all of `/rust` (pulling in `config`,
  `backups`, `docker`, `home`, `nix`, `persist` — none of which should be
  browsable) or bind-mounting media/data under one aggregate root as a
  workaround. Quantum's config just lists both directly:
  ```nix
  server.sources = [
    { path = "/rust/media"; name = "Media"; }
    { path = "/rust/data"; name = "Data"; }
  ];
  ```
  Verified directly (built the package, wrote a matching config, ran it
  against real Media/Data test directories) before wiring this module up
  — confirmed both sources index and show up as separate top-level
  sections, not merged.
- **No existing NixOS module** (classic FileBrowser's `services.filebrowser`
  doesn't apply — Quantum is a different config format/CLI, not a
  drop-in `package` override the way MinIO's package swap was), so this
  module hand-writes the systemd unit directly, config generated via
  `pkgs.formats.yaml`.
- **Admin account bootstrap**: Quantum has no default login — `filebrowser-setup`,
  a one-shot systemd service modeled on `modules/home-assistant.nix`'s
  `hass-install-hacs` pattern, runs `filebrowser-quantum set -u
  "$FILEBROWSER_ADMIN_USER,$FILEBROWSER_ADMIN_PASSWORD" -a` exactly once
  — gated on `ConditionPathExists = "!/var/lib/filebrowser/filebrowser.db"`,
  so a password changed later through the UI is never stomped back to the
  initial value on a later rebuild. Credentials are out-of-repo, same
  pattern as Traefik's `LINODE_TOKEN` — see
  `secrets/extra-files/persist/etc/filebrowser/admin.env.example`.
- **`StateDirectory = "filebrowser";`, not `systemd.tmpfiles.rules`** —
  deliberately the same "directory creation tied to this unit's own
  startup, not an independently-scheduled tmpfiles pass" shape the
  [Failure modes](#failure-modes-hit-during-development) recommends, after nixpkgs'
  own `services.minio` module hit exactly that race using tmpfiles rules
  (see the MinIO section above). `/var/lib/filebrowser` and `/etc/filebrowser`
  are still both regular `environment.persistence` entries — `StateDirectory`
  only fixes the ownership-timing race, actual durability across reboots
  still comes from persistence like everything else here.
- **`RequiresMountsFor = [ "/rust/media" "/rust/data" ];`** on the main
  service — same ordering gap `modules/nfs.nix` already covers for its
  own exports file (the [Failure modes](#failure-modes-hit-during-development)'s
  "NFS export script racing its own ZFS mounts"), just for indexed
  sources instead.

### Traefik

Reverse-proxies every web service behind **two** domain schemes at once,
generated programmatically in `modules/traefik.nix` from a single
`backends = { name = port; ... }` attrset (one source of truth, instead of
hand-duplicating six services across two domains):

- Over the Nebula mesh: `<name>-young.nebula.beardedtek.com`
- Over the LAN: `<name>.young.beardedtek.com`

Every entrypoint binds to **all interfaces** (`:80`/`:443`/`:8099`, no
hardcoded IP) — same convention as every other service in this repo
(Samba, NFS, SSH). Reachability is controlled entirely by the
per-interface firewall rules, which open these ports on both
`config.mySystem.lanInterface` and `"nebula1"`. Translated from the user's
existing `traefik:v3` docker-compose setup: since there's no docker
socket/provider here, dynamic routing is declared directly via
`dynamicConfigOptions` (file provider, wired automatically by the
`services.traefik` module) instead of container labels.

- **Certs**: two separate wildcard certs via DNS-01 (Linode provider) —
  `*.nebula.beardedtek.com` and `*.young.beardedtek.com` — each pinned
  explicitly via `tls.domains` on every router for that domain scheme
  (**not** the entrypoint-level default `tls.domains`, which was tried
  first and doesn't work: it only propagates as something routers
  *inherit*, it doesn't by itself cause Traefik to proactively request a
  cert — confirmed the hard way, `acme.json` stayed empty with zero ACME
  log activity even under real traffic with the correct SNI, until
  explicit per-router `tls.domains` was added). Each backend therefore
  gets two routers (e.g. `jellyfin-young-nebula` and `jellyfin-young-lan`),
  sharing the same backend service.
- **Secret**: `LINODE_TOKEN` comes from `/etc/traefik/traefik.env`
  (`environmentFiles`), an out-of-repo secret delivered the same way as
  Nebula's config — see the [nixos-anywhere installation guide](/docs/installation/nixos-anywhere/)'s secrets
  table. Traefik's Linode DNS provider reads it straight from the process
  environment; no templating needed in the static config.
- **Traefik's own admin dashboard port is 8099, not Traefik's default
  8080** — 8080 is qBittorrent's default webUI port, and both would
  otherwise try to bind the same port. 8099 also matches the original
  compose's external host-port mapping, so it's the same port already
  familiar from that setup. Not to be confused with the *NAS's own*
  status dashboard (the Hugo site, `modules/dashboard.nix`, port 8097,
  routed at `young.nebula.beardedtek.com`/`young.beardedtek.com`) — same
  word, two different things.
- **DNS is out of scope for this repo.** Traefik only handles TLS and
  routing once a request actually arrives — `*.nebula.beardedtek.com`
  needs to resolve to young's Nebula address and `*.young.beardedtek.com`
  to young's LAN address, both managed separately wherever the rest of
  `beardedtek.com`'s DNS lives.

### Local-IP access (`lan-local`, port 8090)

A third way to reach the dashboard, alongside the two domain-based schemes
above: plain `http://<young's LAN IP>:8090/` — no DNS, no TLS, just the
box's bare LAN IP. Useful when DNS is unavailable/misconfigured or it's
just more convenient to type an IP than remember a domain.

- **New entrypoint**, `lan-local`, bound to `:8090` on all interfaces but
  **firewalled to `config.mySystem.lanInterface` only** — deliberately not
  opened on `nebula1`. Nebula already has its own encrypted tunnel and its
  own domain-based routes; this port exists purely for convenient
  unencrypted LAN access, so there's no reason to also expose it over the
  mesh.
- **Why a dedicated port instead of reusing `:80`**: the existing `http`
  entrypoint already binds `:80` on every interface and immediately
  redirects everything to HTTPS. A second entrypoint can't also bind
  `:80` scoped to just the LAN IP (Linux won't allow two listeners on the
  same port), so reworking the existing `:80` entrypoint's redirect
  behavior would've been required instead of just adding a new one — a
  bigger, riskier change for a "nice to have" access path. `8090` was
  chosen as an unused, easy-to-remember port next to Traefik's own 8099.
- **Routing**: a single catch-all router, `local-dashboard`, pointing at
  the same `dashboard` backend service the domain-based `young-nebula`/
  `young-lan` routers use.
- **Per-service tiles on the dashboard link straight to each service's own
  `IP:port`** (e.g. `http://192.168.3.181:8123/` for Home Assistant),
  bypassing Traefik entirely for that hop, rather than routing back through
  a `/<name>/` subpath on port 8090. An earlier version of this feature
  did exactly that — a `PathPrefix(`/<name>`)` router plus a
  `redirectRegex`/`stripPrefix` middleware pair per backend, matching
  qBittorrent's own documented Traefik pattern
  ([qBittorrent wiki](https://github.com/qbittorrent/qBittorrent/wiki/Traefik-Reverse-Proxy-for-Web-UI))
  — but it was dropped in favor of direct `IP:port` links: Home Assistant
  and Frigate have no equivalent to Sonarr/Radarr/Jackett/qBittorrent's
  "URL Base"/strip-prefix support, so they rendered with broken asset
  paths under a subpath, and direct `IP:port` sidesteps that class of
  problem entirely for every backend, not just those two.
- **The dashboard gets each service's port from `metrics.json`**
  (`modules/dashboard.nix`'s `dashboard-metrics` timer already TCP-checks
  every backend's port for its up/down status; the same script now also
  includes the port itself in each service's JSON entry), not a
  hardcoded copy in the Hugo site — `modules/traefik.nix`'s `backends`
  attrset stays the one source of truth. The client-side JS in
  `dashboard/content/services.md` only builds `IP:port` links when it
  detects it was loaded from port `8090`; otherwise tiles link to the
  normal HTTPS domains as before.
- **No "blessed" (browser-trusted) TLS cert is possible for bare-IP
  access.** Publicly-trusted CAs (including Let's Encrypt) only issue
  certs for DNS names or, in very limited/expensive cases, *fixed public*
  IPs — never for private LAN IPs like `192.168.x.x`, since anyone on any
  network could hold the same address and there'd be no way for a CA to
  verify ownership of it. The existing wildcard certs
  (`*.nebula.beardedtek.com`, `*.young.beardedtek.com`) are DNS-name certs
  and can't cover a bare IP either. Practical options if this ever needs
  to be encrypted: keep using the DNS-based HTTPS routes instead of the
  bare IP, or accept a self-signed cert (which still shows a browser
  warning — the "blessed" part of the ask isn't achievable that way). This
  path is deliberately plain HTTP, scoped to the trusted LAN only, on the
  same trust basis as Samba/NFS/Jellyfin/etc. elsewhere in this repo.

## Deploying and updating

Full procedure in the [nixos-anywhere installation guide](/docs/installation/nixos-anywhere/). The short
version for routine updates once the box is already installed:
`nixos-rebuild switch --flake .#young --target-host beardedtek@<ip> --sudo
--impure` from a machine with `secrets/initial-passwords.env` sourced.
Several non-obvious requirements for that command to work at all are
documented in the [Failure modes](#failure-modes-hit-during-development)'s "Remote
deployment" section — trusted-users, sudo's environment stripping, and
the `--impure`/`--option pure-eval false` split between `nixos-rebuild`
and `nixos-anywhere`.

## Failure modes hit during development

Failure modes actually hit while building and operating this system, kept
here so they don't get rediscovered the hard way a second time. Organized
by symptom.

### "Failed to mount /sysroot/nix" (or any pool dataset) at boot

**Symptom:** boot hangs or drops to emergency mode trying to mount `/nix`,
`/persist`, or any pool-backed path, sometimes only on *some* boots.

**Cause:** the dataset has a native (non-legacy) ZFS mountpoint.
`zpool import` (and `zfs mount -a`) auto-mounts any dataset with a native
mountpoint and `canmount=on` as part of the import itself — entirely
outside NixOS's own systemd-generated mount units for the same path. When
both try to mount the same path, they conflict.

**The subtle version of this bug:** even when the paths *do* match and the
first mount succeeds, something later re-triggers ZFS's own auto-mount
(e.g. an activation-triggered `zfs mount -a`) and the second mount
replaces the first, **orphaning** anything already nested underneath it.
The orphaned mount is still listed in the mount table (`mount`, `findmnt`
both show it — they read `/proc/self/mountinfo`, which still has the
entry) but is completely unreachable by path (`ls`, `stat` return ENOENT)
because the directory tree above it changed out from under it. Confirmed
this exact failure for the pool's own top-level dataset specifically — it
was the one dataset that got missed when converting everything else to
`mountpoint=legacy`, since it's easy to forget it's a dataset at all
rather than just "the parent path everything else lives under."

**Fix:** `zfs set mountpoint=legacy <dataset>` for *every* dataset
referenced by a `fileSystems.*` entry — including the pool's own top-level
dataset, not just its children. See the
[nixos-anywhere installation guide](/docs/installation/nixos-anywhere/)
for the one-time `zfs set` commands. Legacy-mountpoint datasets are never
auto-mounted by ZFS, only ever mounted explicitly — which is exactly what
NixOS's systemd-generated units do.

**Diagnosis tip:** if `mount | grep <path>` shows something mounted but
`ls`/`stat` on that exact path fail, check `journalctl -b | grep -iE
"Mounting|Mounted"` for that path — if it mounted more than once in the
same boot, that's the orphaning bug, not a race.

### Declarative `/etc/*` content silently missing (sshd_config, delivered secrets, etc.)

**General principle:** `environment.persistence."/persist"` (impermanence)
bind-mounts whatever directory you list wholesale from `/persist` back
onto the tmpfs root. If you persist a *whole directory* that NixOS also
manages declaratively (writes files into at every activation, e.g. via a
store symlink), the bind mount shadows that declarative content —
whatever's on the persistent side (often nothing, if it's a fresh dataset)
wins, and the declaratively-managed file just never appears.

#### Instance: sshd refused to start, "`/etc/ssh/sshd_config` does not exist"

**Cause:** `/etc/ssh` was listed as a whole directory under
`environment.persistence."/persist".directories`. That shadowed NixOS's
own declarative placement of `sshd_config` (normally a symlink into the
Nix store, regenerated every boot since root is tmpfs) — nothing ever
created that symlink inside the *persisted* copy of the directory.

**Fix:** persist only the specific files that actually need to survive a
reboot (the SSH host keys, so `known_hosts` doesn't break on clients every
time) under `files = [...]`, not the whole directory. See
`hosts/terramaster/young/configuration.nix`'s `environment.persistence` block and
`services.openssh.hostKeys`' actual default (`rsa` + `ed25519`) for which
files that is.

**Live unblock without a rebuild**, if you're already locked out over SSH:
`touch /etc/ssh/sshd_config && systemctl restart sshd` at the console —
an empty-but-existing file lets sshd fall back to compiled-in defaults
(which do allow key-based auth) long enough to push the real fix over
SSH. The temp file disappears on the next reboot regardless, since root
is tmpfs — it's a bridge, not a fix.

#### Instance: Nebula's `config.yaml` empty after install (`/etc/nebula/`)

**Cause:** `nixos-anywhere --extra-files` writes directly onto whatever's
mounted under `/mnt` *during install*. If the extra-files payload targets
a path like `etc/nebula/config.yaml` (mirroring the final `/etc/nebula`
path), it lands on `/mnt/etc/nebula` — which at install time is on the
ephemeral install-scratch filesystem, not `/mnt/persist`. The impermanence
bind-mount from the real pool only starts existing at the *installed*
system's first real boot, and it starts empty — shadowing whatever the
installer wrote to the now-irrelevant ephemeral copy.

**Fix:** structure `secrets/extra-files/` to mirror where the file
actually needs to land at install time, not where it ends up after
boot — i.e. `secrets/extra-files/persist/etc/nebula/config.yaml`, which
`nixos-anywhere` writes to `/mnt/persist/etc/nebula/config.yaml` (a real,
already-mounted persistent dataset per the
[nixos-anywhere installation guide](/docs/installation/nixos-anywhere/)).
Contrast with the SSH key under `secrets/extra-files/home/...` — that one
never had this problem, because `/home` is a real ZFS-backed mount during
install already, not indirected through `/persist`.

**Live unblock on an already-running box:** the target path (e.g.
`/etc/nebula/config.yaml`) really is the persistent one once the system
has booted at least once with the persistence entry active — deliver the
file directly there (`ssh ... 'cat > /tmp/x' < localfile`, then
`sudo install -m 600 /tmp/x /etc/nebula/config.yaml`), no rebuild needed.

### Freshly-created persistence bind-mounts get the wrong ownership (general pattern)

**The general shape of this bug, seen four times now under four
different mechanisms:** the first time `environment.persistence` creates
a brand-new source directory under `/persist` for a service's
`/var/lib/<name>` (i.e. the very first activation after adding a new
persisted path that has no prior data on the pool), something
*else* that's also supposed to set that directory's ownership/contents
races against — or simply never re-runs against — the freshly-created
bind mount. The fix is always the same shape: re-run whatever step was
supposed to set things up, *now that the bind mount already exists*, one
time. After that first correct pass, it's fine on every future boot,
since the directory already has real content/ownership on the persistent
dataset and nothing about it is "fresh" anymore.

Four confirmed instances, four different underlying mechanisms:

- **`systemd.tmpfiles.rules` `z` (fix ownership) lines on a delivered
  secret** (`modules/unix-ldap-login.nix`'s LDAP bind password): the file
  itself was there (out-of-band secret, delivered before the rebuild that
  first introduced its `/etc/unix-ldap-login` persistence entry), but
  nslcd's `preStart` — which runs as the unprivileged `nslcd` user, not
  root — got "Permission denied" reading it. The `z ... root nslcd - -`
  rule meant to fix that was correctly generated
  (`/etc/tmpfiles.d/00-nixos.conf` had it verbatim) but simply hadn't been
  applied yet: same race as the directory-creation case below, just a
  `z` line instead of a `d` line, and a file instead of a directory.
  Symptom: `cat: /etc/<x>/<secret>: Permission denied` in the journal for
  the consuming service, immediately followed by that service failing to
  parse its own config (an empty value from the failed `cat` produces a
  malformed config line downstream — a second-looking symptom with the
  same root cause, not two separate bugs). **Fix:** `sudo systemd-tmpfiles
  --create`, then restart the affected service.
- **`systemd.tmpfiles.settings`-declared directories** (qBittorrent): a
  service crashes because a directory it expects
  (`Profile::ensureDirectoryExists`-style fatal errors, or similar) simply
  doesn't exist, even though its NixOS module declares a
  `systemd.tmpfiles.settings`/`.rules` entry that should create it. On
  the *same* `nixos-rebuild switch` that (a) introduces the new tmpfiles
  rules and (b) creates the brand-new persistence bind-mount, the
  ordering between the two isn't guaranteed — the directories can get
  created on the wrong (pre-bind-mount) instance of the path and then get
  shadowed once the real bind-mount activates. **Fix:** `sudo
  systemd-tmpfiles --create`, then restart the affected service.
- **`users.users.<name>.createHome`** (Home Assistant's `hass` user):
  NixOS's user-activation logic creates a system user's home directory
  with correct ownership *only when it doesn't already exist* — it won't
  retroactively `chown` a directory that's already there. If
  `environment.persistence` gets to create the (empty, `root:root`,
  mode `0755`) bind-mount source first, user-activation sees "the
  directory already exists" and never fixes its ownership. Symptom:
  `mkdir: cannot create directory '/var/lib/<name>/...': Permission
  denied` from a systemd service running as that user. **Fix:** `sudo
  chown -R <user>:<group> /var/lib/<name>`, then restart the affected
  service(s).
- **ZFS's own auto-mount vs. NixOS's explicit mounts** (the pool
  dataset and its children — see above): same underlying "which one gets
  there first" shape, just at the filesystem-mount level instead of a
  directory-ownership level.

**When adding any new service with a `/var/lib/<name>` (or similar)
persistence entry that didn't exist before:** after the first deploy,
check `journalctl`/`systemctl status` for exactly this pattern before
assuming something is actually broken — a one-time ownership/tmpfiles
fixup is very likely all that's needed, not a config bug.

### `DynamicUser=true` + `StateDirectory=` + impermanence: "Device or resource busy"

**Symptom:** a service using `DynamicUser = true` with `StateDirectory =
"<name>"` fails with `Failed to set up special execution directory in
/var/lib: Device or resource busy`, exit code `238/STATE_DIRECTORY`. Hit
with Seerr specifically.

**Cause:** systemd's `DynamicUser` mechanism expects to *own and manage*
`StateDirectory=` itself, including migrating a "pre-existing public"
`/var/lib/<name>` into its own private `/var/lib/private/<name>` scheme —
which requires renaming the directory. If `/var/lib/<name>` is an active
impermanence bind-mount (not a plain directory), that rename fails
outright: you can't rename something with a separate mount actively
attached to it.

**Fix:** override the service to use a fixed system user instead of
`DynamicUser`, so systemd treats the directory as an ordinary
(non-dynamic-user) `StateDirectory=` — just chowned in place, no
migration dance:

```nix
users.users.seerr = { isSystemUser = true; group = "seerr"; };
users.groups.seerr = { };
systemd.services.seerr.serviceConfig = {
  DynamicUser = lib.mkForce false;
  User = "seerr";
  Group = "seerr";
};
```

(Needs `lib` passed into the module's function arguments to use
`lib.mkForce`.)

**Note on the qBittorrent tmpfiles issue above:** services using
`StateDirectory=` *without* `DynamicUser` don't hit that particular race,
because directory creation there is tied to that specific unit's own
startup sequence (guaranteed to run after that unit's own mount
dependencies), not to the independent, globally-scheduled
`systemd-tmpfiles-setup.service`.

### NFS export script racing its own ZFS mounts

**Symptom:** `nfs-server.service` fails with `exportfs: Failed to stat
/rust/data: No such file or directory`, sometimes at boot, sometimes on
a later restart, even though the dataset is genuinely mounted at the time
you go check.

**Cause:** `modules/nfs.nix` generates `/etc/exports` dynamically in a
`preStart` script (needed since the export subnet is auto-detected, not
static — see "Network and firewall model" above). Because that
script's filesystem references live inside a shell script, not a
declarative NixOS option, nothing automatically wires up an ordering
dependency on the ZFS mount units it reads from — `nfs-server.service`
can start, and its `preStart` can run `exportfs`, before those mounts are
actually up.

**Fix:** explicit `RequiresMountsFor`, since there's no `requiresMountsFor`
shorthand for `systemd.services.*` in NixOS — it has to go through
`unitConfig` directly:

```nix
systemd.services.nfs-server.unitConfig.RequiresMountsFor =
  [ "/rust/media" "/rust/data" ];
```

### Jellyfin refuses to start: "insufficient free space" on its cache dir

**Symptom:** `jellyfin.service` crashes immediately on start/restart with
`System.InvalidOperationException: The path '/var/cache/jellyfin' has
insufficient free space`, followed by a full coredump per crash.

**Cause:** Jellyfin's default `cacheDir` (`/var/cache/jellyfin`) lives on
the tmpfs root (2G total, shared with everything else that isn't
explicitly persisted). Jellyfin refuses to even start if its startup
free-space check on that path fails.

**Fix:** redirect `services.jellyfin.cacheDir` to somewhere ZFS-backed —
this repo uses `/var/lib/jellyfin/cache` (already inside the persisted
`/var/lib/jellyfin` directory, so no extra persistence entry needed).

**Secondary risk worth knowing:** a crash-loop here writes a full
coredump per crash to `/var/lib/systemd/coredump`, which is *also* on the
tmpfs root by default — several crash cycles can plausibly fill the 2GB
root and destabilize unrelated services. If a box goes unreachable after
a crash-looping service, check `df -h /` before assuming it's a network
problem.

### Remote deployment gotchas (`nixos-rebuild switch --target-host`)

A handful of non-obvious requirements had to be discovered one at a time
to get routine remote updates working at all, beyond the initial
`nixos-anywhere` install:

- **`root@` doesn't work as the target-host user.** `PermitRootLogin =
  "no"` (see "Network and firewall model" above) blocks it
  entirely, on purpose. Target as a real user with `--sudo` (formerly
  `--use-remote-sudo`) instead — it prompts interactively for that user's
  sudo password over the SSH session.
- **`nix.settings.trusted-users` must include the deploying user** (this
  repo uses `[ "@wheel" ]`). Without it, the target's Nix daemon refuses
  unsigned store paths pushed from a non-root, non-trusted user with
  `error: ... lacks a signature by a trusted key`. Chicken-and-egg
  warning: fixing this *itself* requires deploying the fix, which is
  blocked by the same restriction — break the loop by applying that one
  change locally on the box (console/SSH shell, `sudo nixos-rebuild
  switch --flake .#<host> --impure`, no `--target-host`) once.
- **`sudo` strips the environment by default.** Running
  `nixos-rebuild switch --impure` locally via plain `sudo` loses the
  initial-password env vars even after sourcing
  `secrets/initial-passwords.env`, causing the config's own assertions to
  fail as if they were never set. Use `sudo --preserve-env=VAR1,VAR2,VAR3`
  explicitly.
- **Don't pass `--build-host localhost`.** It's not a no-op — it makes
  `nixos-rebuild` reach the "build host" over actual SSH even when it's
  named `localhost`, which fails with `Connection refused` on any machine
  without its own sshd running. Omit `--build-host` entirely to build
  locally with no SSH involved; only `--target-host` needs SSH.
- **`--impure` vs `--option pure-eval false`.** Plain `nix build` /
  `nixos-rebuild switch` accept `--impure` directly. `nixos-anywhere`
  does not — everything after its own `--` is parsed by its own argument
  parser, which doesn't recognize `--impure` and just dumps usage text.
  Use `--option pure-eval false` for `nixos-anywhere` specifically;
  confirmed it achieves the same effect (and that the config's assertions
  still correctly fire if the secret env vars aren't set).

### Stray `_acme-challenge.*` CNAME breaks DNS-01 for that domain

**Symptom:** `traefik.log` shows real ACME/DNS-01 activity (unlike the
entrypoint-level `tls.domains` issue above — this is a config problem in
the DNS zone itself, not in Traefik), but validation fails. Two variants
hit in practice:

- `No TXT record found at _acme-challenge.<domain>` after lego repeatedly
  reports `Found CNAME entry` and waits for propagation that never
  resolves — happened for `nebula.beardedtek.com`, where
  `_acme-challenge.nebula.beardedtek.com` had a CNAME pointing at
  `nebula.beardedtek.com` itself (a self-referential loop: nothing is ever
  actually there to find).
- `no subdomain because the domain and the zone are identical:
  <zone>.` — happened for `young.beardedtek.com`, where
  `_acme-challenge.young.beardedtek.com` had a CNAME pointing straight at
  the zone apex (`beardedtek.com`), which the Linode API can't accept a
  record "under" since it's not a subdomain of itself.

**Cause:** a leftover `_acme-challenge.<domain>` CNAME record already
existed in the Linode zone for both domains used by `modules/traefik.nix`,
predating this setup. Per the DNS-01 spec, lego (correctly) follows a
CNAME at the challenge FQDN instead of writing a TXT record there directly
— so a stray CNAME left over from unrelated/earlier configuration silently
hijacks every future ACME validation for that name, no matter how correct
the Traefik/NixOS config is.

**Fix:** in Linode's DNS Manager, delete the specific
`_acme-challenge.<domain>` CNAME record for whichever domain is failing.
Nothing in this repo creates or needs one — lego creates its own TXT
record directly once the CNAME is gone. Then `sudo systemctl restart
traefik` and watch `traefik.log` again.

**Given this has now happened for every wildcard domain added to this
setup so far:** before adding a *new* wildcard domain to
`modules/traefik.nix`, check the Linode zone for an existing
`_acme-challenge.<new-domain>` record first, rather than debugging it
after the fact.

### Traefik/qBittorrent port collision

**Symptom:** would manifest as one of the two services failing to bind
its port if both were left at their defaults.

**Cause:** Traefik's insecure-API dashboard defaults to port 8080 (via
`--api.insecure=true`, no explicit entrypoint declared) — which is also
qBittorrent's default `webuiPort`. Both binding to the same address on
port 8080 collides.

**Fix:** explicitly declared Traefik's dashboard `entryPoints.traefik.address`
to a different port instead of relying on the default — see
`modules/traefik.nix`. Worth checking for any *future* service added to
this box too: ports aren't auto-negotiated here, each one needs an
explicit, distinct assignment.

### Installer wizard validation

The ISO installer wizard (see the
[ISO installer guide](/docs/installation/iso/)) was validated with a
full, real end-to-end run in a VirtualBox VM (EFI firmware, 4 blank
virtual disks + 1 boot disk, 8GB RAM): booted the ISO, drove the wizard
through the *new pool* (destructive) path, confirmed `disko` actually
partitioned/created the pool and `nixos-install` completed successfully,
then rebooted into the newly installed system and confirmed the ZFS pool
imported cleanly and the created user could log in. Several real bugs
were only found this way (not by static `nix eval`/`nix build` checks)
and are now fixed:

- The console's autologin user is `nixos` (unprivileged), not `root` —
  the wizard now always runs itself via `sudo`.
- `cp -r` on a symlink into the read-only Nix store recreated the symlink
  instead of copying real content — fixed with `cp -rL`.
- `/dev/disk/by-id/` also lists the optical drive holding the ISO itself
  (and, on real hardware, would list whatever USB stick the ISO was
  booted from) — both are now excluded from disk-selection lists.
- `disko` has its own separate "type yes" confirmation that would hang
  waiting for input the wizard never prompted for — skipped with
  `--yes-wipe-all-disks`, since the wizard's own typed-`DESTROY` gate
  already covers that consent.
- disko's auto-generated `/persist` filesystem entry doesn't set
  `neededForBoot`, which impermanence requires — now set explicitly for
  the new-pool path.
- **The most important one**: a freshly-created pool gets stamped with
  the *live installer's own* hostid (hardcoded, not the target's), so
  the target's first real boot would fail to auto-import it. The wizard
  now stamps the live session's hostid to match the target's *before*
  creating the pool — and since `/etc/hostid` is itself a Nix-store
  symlink on this ISO, doing that requires removing the symlink first
  (same class of bug as the `cp -r` one above).
- `umount -R /mnt` fails ("not mounted") since `/mnt` itself is never a
  mountpoint, only its children are — replaced with an explicit
  deepest-first unmount of everything actually mounted under it.

Budget real RAM for the install step specifically: unlike
`nixos-anywhere` (builds on your workstation, only copies the result),
the wizard builds the *entire* target system locally, on whatever
hardware it's running on. 3GB RAM was not enough in testing — the build
was OOM-killed partway through compiling Home Assistant's Python
dependencies; 8GB completed the full build without issue.

Not yet run against real hardware — treat the first real run on new
hardware as a trial, not a guarantee, and keep a way to reach the console
in case something needs a closer look.
