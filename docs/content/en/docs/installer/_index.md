---
title: Installer ISO
linkTitle: Installer
weight: 30
description: A self-contained, bootable installer with a TUI wizard for provisioning a new NAS.
---

A self-contained, bootable installer for provisioning a new NAS under
this flake — a TUI wizard walks through networking, storage, users, and
which services to enable, then installs NixOS itself. No separate
workstation orchestration needed (unlike the
[deployment doc](/docs/deployment/)'s `nixos-anywhere`-driven flow, which
remains the documented path for `young` specifically, and as the manual
reference for what this wizard automates).

## Building the ISO

```sh
nix build --impure '.#nixosConfigurations.installer.config.system.build.isoImage'
```

The result (`result/iso/*.iso`) has a full copy of this repo baked in as
of build time — see "Repo freshness" below for what that means in
practice. If `secrets/extra-files/home/beardedtek/.ssh/authorized_keys`
exists locally when you build, it's baked into the ISO's `root` account
too, for convenience; if not, the wizard falls back to the same
`passwd`-then-SSH dance the [deployment doc](/docs/deployment/) step 2
already documents for the stock ISO.

Flash the result to a USB drive the same way as any NixOS ISO
(`dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress` from another
Linux machine, or Rufus/balenaEtcher on Windows/macOS).

## What the wizard does

Boots to a TUI (also reachable over SSH — `ssh root@<installer-ip>`, key
or temporary password per above) that walks through, in order:

1. **Repo freshness** — offers to `git clone` a fresh copy from GitHub
   before generating anything, in case the ISO is older than the repo.
   Falls back to the baked-in copy if there's no network or the clone
   fails — nothing is lost either way.
2. **Network** — pick the LAN interface.
3. **Instance identity** — manufacturer, instance name (becomes
   `hosts/<manufacturer>/<instance>/`), hostname, ZFS hostid.
4. **Storage** — the one genuinely consequential choice:
   - **Adopt an existing pool**: non-destructive. Imports the pool,
     fixes every existing dataset's `mountpoint` property to `legacy`
     (metadata-only — see the [architecture doc](/docs/architecture/)'s
     "every dataset must be `mountpoint=legacy`" explanation), creates
     `nix`/`persist` datasets if they're missing, and asks which existing
     datasets to use for `home`/`media`/`data`. This is exactly the
     [deployment doc](/docs/deployment/) step 3, automated and
     generalized to any pool's actual dataset list instead of a
     hardcoded one.
   - **Create a new pool**: destructive. Disk discovery flags any disk
     with an existing filesystem/RAID/ZFS signature and excludes it from
     the pool by default — including one requires an explicit
     per-disk confirmation. Uses `lib/zfs-pool.nix` (the same function
     `hosts/terramaster/f4-245/`'s template uses) to generate a real
     `disko.nix`, shown in full before you're asked to type `DESTROY`
     (not just click yes/no) to actually run it.
5. **Users** — add each user (name, sudo or not, password — hashed
   locally with `mkpasswd -m sha-512`; plaintext never touches disk).
6. **Services** — a checklist matching `mySystem.features`' exact shape
   (`modules/common.nix`).
7. **Secrets** — SSH access for the first user. Looks for a USB drive
   labeled `NAS-SECRETS` first (its own flat layout —
   `authorized_keys`, `etc/nebula/config.yaml`, `etc/traefik/traefik.env` —
   not the [deployment doc](/docs/deployment/)'s `secrets/extra-files/`
   tree, which is nested under a hardcoded `beardedtek` username that
   doesn't generalize to a wizard-chosen admin user) for `authorized_keys`
   and (optionally) Nebula/Traefik secrets. If no USB key is found, offers
   three ways to set up SSH access instead of demanding a key be pasted by
   hand — unrealistic from a TUI on a box that may not even be near a
   keyboard with the key on it:
   - **Fetch from a GitHub username** — pulls `https://github.com/<user>.keys`
     (that endpoint is a plain-text list of every public key attached to
     the account, no auth needed). Needs network access, same as every
     other step from here on.
   - **Paste an SSH public key directly** — the original flow, still
     available.
   - **Use a password instead** — skips requiring a key entirely and sets
     `mySystem.security.sshPasswordAuth = true;` in the generated
     `variables.nix`, so the installed system accepts the password set in
     the Users step over SSH. Off by default everywhere else in this flake
     (see the [architecture doc](/docs/architecture/)'s "Network and
     firewall model" section) — the wizard warns before enabling it, and
     root login stays disabled regardless of which option is picked.

   Nebula/Traefik secrets are optional either way; skipping them just
   means configuring those services manually post-install, same as
   leaving `CHANGEME` placeholders unfilled today.
8. **Review** — full summary, then the destructive-path confirmation
   described above (new pool) or a plain yes/no (existing pool, since
   nothing on that path deletes data).
9. **Install** — writes `variables.nix`, `hosts/<manufacturer>/<instance>/{disko.nix,configuration.nix}`,
   and `secrets/initial-passwords.env` into its working checkout, runs
   the actual storage setup, then `nixos-install`.

## After it finishes

The generated files are copied to `/persist/nixos-installer-output/` on
the newly installed system — retrieve them (`scp` or the Samba share) and
commit them into your own git checkout of this repo. The wizard never
pushes to git itself. `secrets/initial-passwords.env` is deliberately
*not* included in that copy (it only mattered for this one install);
recreate it locally from `secrets/initial-passwords.env.example` if
you'll be rebuilding this box from a workstation later, per the
[deployment doc](/docs/deployment/).

## What this doesn't do (yet)

- No unattended/non-interactive mode — every run is interactive.
- Pasting a full Nebula config through the wizard isn't implemented; use
  a `NAS-SECRETS` USB drive or configure it manually after first boot.

## Resource requirements for the install step itself

Unlike `nixos-anywhere` (which builds on your workstation and only copies
the result to the target), this wizard builds the *entire* target system
— Traefik, the media stack, Home Assistant, Frigate, etc. — locally, on
whatever hardware it's running on. That means:

- **Network access is required** during the install step, even though
  the wizard's own UI/tooling is fully baked into the ISO — `disko` and
  `nixos-install` both need to fetch `nixpkgs`/`disko`/`impermanence` and
  every package the enabled services pull in (several GB, depending on
  which services you leave checked in the features step).
- **Budget real RAM for the build.** Validated end-to-end in a VirtualBox
  VM: 3GB RAM was not enough — the build was OOM-killed partway through
  compiling Home Assistant's Python dependencies. 8GB completed the full
  build (Traefik, the whole media stack, Home Assistant, Frigate)
  without issue. The F4-245's 16GB should have ample headroom; a
  lower-RAM target might need fewer services enabled for the initial
  install.

## Validation status

Verified with a full, real end-to-end run in a VirtualBox VM (EFI
firmware, 4 blank virtual disks + 1 boot disk, 8GB RAM): booted the ISO,
drove the wizard through the *new pool* (destructive) path, confirmed
`disko` actually partitioned/created the pool and `nixos-install`
completed successfully, then rebooted into the newly installed system
and confirmed the ZFS pool imported cleanly (`ONLINE`, 0 errors) and the
created user could log in. Several real bugs were only found this way
(not by static `nix eval`/`nix build` checks) and are now fixed:

- The console's autologin user is `nixos` (unprivileged), not `root` —
  the wizard now always runs itself via `sudo`.
- `cp -r` on `/etc/nas-installer-repo` (a symlink into the read-only Nix
  store) recreated the symlink instead of copying real content — fixed
  with `cp -rL`.
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

Not yet run against real hardware — treat the first real F4-245 run as a
trial, not a guarantee, and keep a way to reach the console (monitor/
keyboard, or SSH per above) in case something needs a closer look.
