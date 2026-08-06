---
title: Radarr
linkTitle: Radarr
weight: 30
description: Automated movie acquisition and library management.
---

## Information and purpose

[Radarr](https://radarr.video/) monitors for movies you want, searches
configured indexers for them, and hands matches off to a download client
— then imports and renames the finished file into your library
automatically.

## Configuration

- **Access**: `https://radarr.<your-nas>.<domain>/`, the Nebula
  equivalent if configured, or directly at `http://<nas-ip>:7878/`.
- **Login**: its own separate account system, set up on first visit.
- **Download client**: pre-wired to this box's qBittorrent instance.
- **Indexers**: connect through Jackett (or add indexers directly if they
  support it natively).
- **Library**: writes into this box's shared media library, the same one
  Jellyfin serves from.

## Usage

See the [Servarr Wiki's Radarr section](https://wiki.servarr.com/radarr)
for adding indexers, quality profiles, and root folders.
