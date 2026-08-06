---
title: qBittorrent
linkTitle: qBittorrent
weight: 60
description: The download client behind Radarr/Sonarr.
---

## Information and purpose

[qBittorrent](https://www.qbittorrent.org/) is the download client that
Radarr and Sonarr hand completed matches to. You generally won't need to
use it directly — it's driven automatically — but its Web UI is available
if you want to see what's downloading or manage it by hand.

## Configuration

- **Access**: `https://qbittorrent.<your-nas>.<domain>/`, the Nebula
  equivalent if configured, or directly at `http://<nas-ip>:8080/`.
- **Login**: its own separate Web UI password, set on first visit.
- **Downloads**: writes into this box's shared downloads/data area, the
  same location Radarr and Sonarr import from.

## Usage

See the [qBittorrent wiki](https://github.com/qbittorrent/qBittorrent/wiki/)
for Web UI options and settings.
