# Troubleshooting and known gotchas

Failure modes actually hit while building and operating this system, kept
here so they don't get rediscovered the hard way a second time. Organized
by symptom. See `docs/ARCHITECTURE.md` for the design context these
mostly stem from.

## "Failed to mount /sysroot/nix" (or any `rust/*` dataset) at boot

**Symptom:** boot hangs or drops to emergency mode trying to mount `/nix`,
`/persist`, or any `/rust/*` path, sometimes only on *some* boots.

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
this exact failure for the pool's own top-level `rust` dataset specifically
— it was the one dataset that got missed when converting everything else
to `mountpoint=legacy`, since it's easy to forget it's a dataset at all
rather than just "the parent path everything else lives under."

**Fix:** `zfs set mountpoint=legacy <dataset>` for *every* dataset
referenced by a `fileSystems.*` entry — including the pool's own top-level
dataset, not just its children. See `docs/DEPLOYMENT.md` step 3 for the
full command list. Legacy-mountpoint datasets are never auto-mounted by
ZFS, only ever mounted explicitly — which is exactly what NixOS's
systemd-generated units do.

**Diagnosis tip:** if `mount | grep <path>` shows something mounted but
`ls`/`stat` on that exact path fail, check `journalctl -b | grep -iE
"Mounting|Mounted"` for that path — if it mounted more than once in the
same boot, that's the orphaning bug, not a race.

## Declarative `/etc/*` content silently missing (sshd_config, delivered secrets, etc.)

**General principle:** `environment.persistence."/persist"` (impermanence)
bind-mounts whatever directory you list wholesale from `/persist` back
onto the tmpfs root. If you persist a *whole directory* that NixOS also
manages declaratively (writes files into at every activation, e.g. via a
store symlink), the bind mount shadows that declarative content —
whatever's on the persistent side (often nothing, if it's a fresh dataset)
wins, and the declaratively-managed file just never appears.

### Instance: sshd refused to start, "`/etc/ssh/sshd_config` does not exist"

**Cause:** `/etc/ssh` was listed as a whole directory under
`environment.persistence."/persist".directories`. That shadowed NixOS's
own declarative placement of `sshd_config` (normally a symlink into the
Nix store, regenerated every boot since root is tmpfs) — nothing ever
created that symlink inside the *persisted* copy of the directory.

**Fix:** persist only the specific files that actually need to survive a
reboot (the SSH host keys, so `known_hosts` doesn't break on clients every
time) under `files = [...]`, not the whole directory. See
`hosts/young/configuration.nix`'s `environment.persistence` block and
`services.openssh.hostKeys`' actual default (`rsa` + `ed25519`) for which
files that is.

**Live unblock without a rebuild**, if you're already locked out over SSH:
`touch /etc/ssh/sshd_config && systemctl restart sshd` at the console —
an empty-but-existing file lets sshd fall back to compiled-in defaults
(which do allow key-based auth) long enough to push the real fix over
SSH. The temp file disappears on the next reboot regardless, since root
is tmpfs — it's a bridge, not a fix.

### Instance: Nebula's `config.yaml` empty after install (`/etc/nebula/`)

**Cause:** `nixos-anywhere --extra-files` writes directly onto whatever's
mounted under `/mnt` *during install*. If the extra-files payload targets
a path like `etc/nebula/config.yaml` (mirroring the final `/etc/nebula`
path), it lands on `/mnt/etc/nebula` — which at install time is on the
ephemeral install-scratch filesystem, not `/mnt/persist`. The impermanence
bind-mount from `rust/persist` only starts existing at the *installed*
system's first real boot, and it starts empty — shadowing whatever the
installer wrote to the now-irrelevant ephemeral copy.

**Fix:** structure `secrets/extra-files/` to mirror where the file
actually needs to land at install time, not where it ends up after
boot — i.e. `secrets/extra-files/persist/etc/nebula/config.yaml`, which
`nixos-anywhere` writes to `/mnt/persist/etc/nebula/config.yaml` (a real,
already-mounted `rust/persist` dataset per `docs/DEPLOYMENT.md` step 4b).
Contrast with the SSH key under `secrets/extra-files/home/...` — that one
never had this problem, because `/home` is a real ZFS-backed mount during
install already, not indirected through `/persist`.

**Live unblock on an already-running box:** the target path (e.g.
`/etc/nebula/config.yaml`) really is the persistent one once the system
has booted at least once with the persistence entry active — deliver the
file directly there (`ssh ... 'cat > /tmp/x' < localfile`, then
`sudo install -m 600 /tmp/x /etc/nebula/config.yaml`), no rebuild needed.

## `systemd-tmpfiles` rules never applied after a live `nixos-rebuild switch` (not a reboot)

**Symptom:** a service crashes because a directory it expects
(`Profile::ensureDirectoryExists`-style fatal errors, or similar) simply
doesn't exist, even though its NixOS module declares a
`systemd.tmpfiles.settings`/`.rules` entry that should create it.

**Cause:** on the *same* `nixos-rebuild switch` that (a) introduces a new
service's tmpfiles rules and (b) creates a brand new
`environment.persistence` bind-mount for that service's `/var/lib/<name>`
directory, the ordering between the two isn't guaranteed. If the tmpfiles
rule application happens before the bind-mount is fully in place, the
directories get created on the wrong (pre-bind-mount) instance of the
path and are then shadowed once the real bind-mount activates. Confirmed
for qBittorrent (`systemd.tmpfiles.settings` in its NixOS module, entirely
independent of the `qbittorrent.service` unit's own dependency chain,
unlike a service using `StateDirectory=` — see below for why that
distinction matters).

**Fix, live and immediate, no reboot needed:** `sudo systemd-tmpfiles
--create` after the switch, then restart the affected service. Only
needed once — after the persistence bind-mount and the tmpfiles rule have
both run *in the right order* a single time, the directories exist for
good.

## `DynamicUser=true` + `StateDirectory=` + impermanence: "Device or resource busy"

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

## NFS export script racing its own ZFS mounts

**Symptom:** `nfs-server.service` fails with `exportfs: Failed to stat
/rust/data: No such file or directory`, sometimes at boot, sometimes on
a later restart, even though the dataset is genuinely mounted at the time
you go check.

**Cause:** `modules/nfs.nix` generates `/etc/exports` dynamically in a
`preStart` script (needed since the export subnet is auto-detected, not
static — see `docs/ARCHITECTURE.md`). Because that script's filesystem
references live inside a shell script, not a declarative NixOS option,
nothing automatically wires up an ordering dependency on the ZFS mount
units it reads from — `nfs-server.service` can start, and its `preStart`
can run `exportfs`, before those mounts are actually up.

**Fix:** explicit `RequiresMountsFor`, since there's no `requiresMountsFor`
shorthand for `systemd.services.*` in NixOS — it has to go through
`unitConfig` directly:

```nix
systemd.services.nfs-server.unitConfig.RequiresMountsFor =
  [ "/rust/media" "/rust/data" ];
```

## Jellyfin refuses to start: "insufficient free space" on its cache dir

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

## Remote deployment gotchas (`nixos-rebuild switch --target-host`)

A handful of non-obvious requirements had to be discovered one at a time
to get routine remote updates working at all, beyond the initial
`nixos-anywhere` install:

- **`root@` doesn't work as the target-host user.** `PermitRootLogin =
  "no"` (see `docs/ARCHITECTURE.md`) blocks it entirely, on purpose.
  Target as `beardedtek@<host>` (or `dyoung@`) with `--sudo` (formerly
  `--use-remote-sudo`) instead — it prompts interactively for that user's
  sudo password over the SSH session.
- **`nix.settings.trusted-users` must include the deploying user** (this
  repo uses `[ "@wheel" ]`). Without it, the target's Nix daemon refuses
  unsigned store paths pushed from a non-root, non-trusted user with
  `error: ... lacks a signature by a trusted key`. Chicken-and-egg
  warning: fixing this *itself* requires deploying the fix, which is
  blocked by the same restriction — break the loop by applying that one
  change locally on the box (console/SSH shell, `sudo nixos-rebuild
  switch --flake .#young --impure`, no `--target-host`) once.
- **`sudo` strips the environment by default.** Running
  `nixos-rebuild switch --impure` locally via plain `sudo` loses the
  `BEARDEDTEK_INITIAL_HASH`/etc. env vars even after `source
  secrets/initial-passwords.env`, causing the config's own assertions to
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

## Traefik/qBittorrent port collision

**Symptom:** would manifest as one of the two services failing to bind
its port if both were left at their defaults.

**Cause:** Traefik's insecure-API dashboard defaults to port 8080 (via
`--api.insecure=true`, no explicit entrypoint declared) — which is also
qBittorrent's default `webuiPort`. Both binding to `10.100.0.17:8080`
(or one to `0.0.0.0:8080`, which still overlaps) collides.

**Fix:** explicitly declared Traefik's dashboard `entryPoints.traefik.address
= "10.100.0.17:8099"` instead of relying on the default — see
`modules/traefik.nix`. Worth checking for any *future* service added to
this box too: ports aren't auto-negotiated here, each one needs an
explicit, distinct assignment.
