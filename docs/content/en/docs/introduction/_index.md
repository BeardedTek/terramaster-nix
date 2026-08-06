---
title: Introduction
linkTitle: Introduction
weight: 10
description: What Bearded NAS is and what it gives you.
---

Bearded NAS is a NixOS distro for low-powered NAS hardware such as
TerraMaster and QNAP devices. It turns a small appliance into a fully
declarative NixOS box, configured from one file and deployed the same way
every time — no manual clicking through a vendor's web UI, no configuration
that only lives on the one box you set it up on.

## What you get

- **ZFS storage** — adopt a pool you already have, or let the installer
  create one from blank drives.
- **File sharing** — Samba and NFS shares over your existing data.
- **A media stack** — Jellyfin, Sonarr, Radarr, Jackett, qBittorrent, and
  Seerr, wired together and pointed at the same library.
- **Home automation** — Home Assistant, with HACS and optional Z-Wave
  support.
- **One login everywhere** — every service authenticates against a single
  LLDAP directory, including the web dashboard and (optionally) the box's
  own console/`sudo` login.
- **A web dashboard** — live storage/service status, and a self-service
  update button, all from your browser.
- **Reach it your way** — every service is reachable on your LAN, and
  optionally over a Nebula mesh VPN for access away from home.

## Where to go next

- **[Installation](/docs/installation/)** — bring up a new box, either with
  the guided installer ISO or manually via `nixos-anywhere`.
- **[Usage](/docs/usage/)** — once it's running: logging in, the
  dashboard, managing users, and every available service.
- **[Troubleshooting](/docs/troubleshooting/)** — common problems and what
  to do about them.

If you're extending or maintaining the flake itself rather than just
running it, see **[Architecture](/docs/architecture/)** for the design
rationale and internals.
