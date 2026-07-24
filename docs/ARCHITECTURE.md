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
| Traefik (proxy) | `modules/traefik.nix` | 80/443/8099/8090 | LAN + nebula1 (8090: LAN only) |
| Dashboard (nginx) | `modules/dashboard.nix` | 8097 | LAN + nebula1 |
| Frigate (via its own nginx vhost) | `modules/frigate.nix` | 8098 | LAN + nebula1 |
| Home Assistant | `modules/home-assistant.nix` | 8123 | LAN + nebula1 |
| Mosquitto (MQTT) | `modules/home-assistant.nix` | 1883 | LAN + nebula1 |

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
  `docs/TROUBLESHOOTING.md`).
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
  a list of `{ label, email, phone }` entries, set per-host in
  `hosts/young/configuration.nix` rather than hardcoded into the Hugo
  content. `modules/dashboard.nix` serializes it to `data/contact.json`
  and copies it into the Hugo source tree at build time (Hugo auto-loads
  any `data/*.json` as `.Site.Data.contact`), read by
  `dashboard/layouts/partials/contact-info.html` — shared by the footer
  (every page) and the Help page's `{{< contact >}}` shortcode, so there's
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
directory. Full writeup, including the reverse-proxy `trusted_proxies`
requirement and how to enable Z-Wave once the dongle arrives, is in
**`docs/HOME-ASSISTANT.md`**.

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
  Nebula's config — see `docs/DEPLOYMENT.md`'s secrets table. Traefik's
  Linode DNS provider reads it straight from the process environment; no
  templating needed in the static config.
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

Full procedure in `docs/DEPLOYMENT.md`. The short version for routine
updates once the box is already installed: `nixos-rebuild switch --flake
.#young --target-host beardedtek@<ip> --sudo --impure` from a machine with
`secrets/initial-passwords.env` sourced. Several non-obvious requirements
for that command to work at all are documented in
`docs/TROUBLESHOOTING.md`'s "Remote deployment" section — trusted-users,
sudo's environment stripping, and the `--impure`/`--option pure-eval
false` split between `nixos-rebuild` and `nixos-anywhere`.
