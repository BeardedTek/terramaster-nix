---
title: Seerr
linkTitle: Seerr
weight: 20
description: Request new movies and TV shows to be added to the library.
---

## Information and purpose

[Seerr](https://github.com/seerr-team/seerr) (formerly Jellyseerr/Overseerr)
is a request-management front end — lets you or anyone you invite browse
for movies and shows and request them, without needing direct access to
Radarr/Sonarr/qBittorrent themselves.

## Configuration

- **Access**: `https://seerr.<your-nas>.<domain>/`, the Nebula equivalent
  if configured, or directly at `http://<nas-ip>:5055/`.
- **Login**: connects to Jellyfin as its media-server backend — sign in
  with your Jellyfin account on first visit.
- **Backend**: pre-wired to this box's Radarr and Sonarr instances, so
  approved requests are sent there automatically.

## Usage

See Seerr's own [documentation](https://docs.seerr.dev/) for requesting
titles, managing request approval, and user permissions.
