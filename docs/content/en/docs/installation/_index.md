---
title: Installation
linkTitle: Installation
weight: 20
description: Boot the guided installer ISO and answer questions — on the NAS's own screen if it has one, or from any other device's browser if it doesn't.
---

One consequential decision about storage comes right up front, before
anything else happens — everything past that is fully guided, whether
you're driving it from the NAS's own screen or a remote browser.

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

## However you reach it, it's the same wizard

Boot the [installer ISO](/docs/installation/iso/) and the box figures out
how to show it to you:

- **A display is connected** — boots straight into the installer
  full-screen, no separate device needed to drive the install.
- **No display detected** — falls back cleanly to a text-mode console
  wizard, and the same install is also always reachable from any other
  device's browser on the LAN at the IP address the console prints on
  boot. A remote browser and the local console can drive the exact same
  install interchangeably.

See [ISO Installation](/docs/installation/iso/) for the full walkthrough,
screenshots included.
