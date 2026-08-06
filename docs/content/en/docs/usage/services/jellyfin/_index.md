---
title: Jellyfin
linkTitle: Jellyfin
weight: 10
description: Media server for movies and TV.
---

## Information and purpose

[Jellyfin](https://jellyfin.org/) is a free, self-hosted media server —
organizes your movie and TV library and streams it to apps on phones,
TVs, and browsers, with optional hardware-accelerated transcoding.

## Configuration

- **Access**: `https://jellyfin.<your-nas>.<domain>/`, the Nebula
  equivalent if configured, or directly at `http://<nas-ip>:8096/`.
- **Login**: on hardware that supports it, Jellyfin is configured for
  LDAP login — sign in with your [LLDAP](/docs/usage/lldap/) username and
  password, same as everywhere else. Where LDAP login isn't set up,
  Jellyfin uses its own separate account system instead.
- **Library**: points at this box's shared media storage — the same
  library Sonarr and Radarr import completed downloads into.
- **Hardware transcoding**: enabled where the hardware supports it, but
  still needs turning on by hand once, in Jellyfin's own
  Dashboard → Playback settings.

## Usage

See [Jellyfin's own documentation](https://jellyfin.org/docs/) for adding
libraries, managing users, and setting up client apps.
