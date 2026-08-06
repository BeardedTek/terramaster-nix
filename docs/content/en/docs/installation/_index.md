---
title: Installation
linkTitle: Installation
weight: 20
description: Two ways to install Bearded NAS — the guided installer ISO, or nixos-anywhere from a workstation.
---

Both installation paths ask you to make the same one consequential
decision about storage before anything else happens. Everything past that
is either fully guided (the installer ISO) or a manual step-by-step
(`nixos-anywhere`).

## Storage: blank drives or an existing ZFS pool

- **Blank drives** — the installer creates a new ZFS pool from scratch
  (RAIDZ1, mirror, RAIDZ2, or a plain stripe) across whichever disks you
  point it at. **This is destructive**: every disk you select is wiped.
  Disk discovery flags anything with an existing filesystem/RAID/ZFS
  signature and excludes it by default — including one requires an
  explicit, per-disk confirmation, so you can't wipe a drive with data on
  it by accident.
- **An existing ZFS pool** — if you already have a pool with data on it
  (for example, migrating from an existing NAS OS onto this distro),
  it's *imported*, not recreated. Every dataset's `mountpoint` property
  gets fixed to `legacy` (a metadata-only change — nothing is moved,
  copied, or deleted), two new datasets are added for the system itself
  (`nix` and `persist`), and you're asked which existing datasets to use
  for your home directory, media library, and downloads/data folder.

Either way, the box's root filesystem itself runs from RAM (`tmpfs`) —
nothing routine gets written to the boot drive, and only what's explicitly
marked to survive a reboot does. See
[Architecture → Storage design](/docs/architecture/#storage-design) if
you want the full mechanical explanation of why.

## Choose a path

- **[ISO Installation](/docs/installation/iso/)** (default) — boot a
  self-contained installer, answer questions in a TUI wizard, done. No
  separate workstation required.
- **[nixos-anywhere](/docs/installation/nixos-anywhere/)** — install
  remotely from another machine by editing the flake's config files
  directly first. More manual, but scriptable and repeatable — useful if
  you're managing this as infrastructure-as-code from day one.
