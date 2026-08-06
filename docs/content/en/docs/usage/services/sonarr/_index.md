---
title: Sonarr
linkTitle: Sonarr
weight: 40
description: Automated TV episode acquisition and library management.
---

## Information and purpose

[Sonarr](https://sonarr.tv/) is Radarr's counterpart for TV — monitors
shows for new episodes, searches indexers, hands matches to a download
client, and imports the result into your library automatically.

## Configuration

- **Access**: `https://sonarr.<your-nas>.<domain>/`, the Nebula
  equivalent if configured, or directly at `http://<nas-ip>:8989/`.
- **Login**: its own separate account system, set up on first visit.
- **Download client**: pre-wired to this box's qBittorrent instance.
- **Indexers**: connect through Jackett (or add indexers directly if they
  support it natively).
- **Library**: writes into this box's shared media library, the same one
  Jellyfin serves from.

## Usage

See the [Servarr Wiki's Sonarr section](https://wiki.servarr.com/sonarr)
for adding indexers, quality profiles, and root folders.
