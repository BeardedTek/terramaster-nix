---
title: Available Services
linkTitle: Available Services
weight: 30
description: What's running, how it's set up here, and where to go for detailed usage of each one.
---

Every service below is optional — what's actually enabled on your box is
controlled by `variables.nix`, and mirrored one-to-one in the installer's
Services step and the dashboard's
[Services page](/docs/usage/webui/#services). Each page here covers three
things: what the service is for, how it's already set up on this distro
(authentication, storage, where to reach it), and where to go for full
usage instructions — these are established upstream projects with their
own documentation, so usage details live there rather than being
duplicated here.

- **[Jellyfin](/docs/usage/services/jellyfin/)** — media server
- **[Seerr](/docs/usage/services/seerr/)** — media requests
- **[Radarr](/docs/usage/services/radarr/)** — movie acquisition
- **[Sonarr](/docs/usage/services/sonarr/)** — TV acquisition
- **[Jackett](/docs/usage/services/jackett/)** — indexer proxy
- **[qBittorrent](/docs/usage/services/qbittorrent/)** — download client
- **[Frigate](/docs/usage/services/frigate/)** — camera NVR
- **[Home Assistant](/docs/usage/services/home-assistant/)** — home
  automation, plus HACS, Z-Wave, and MQTT
- **[MinIO](/docs/usage/services/minio/)** — S3-compatible object storage
- **[FileBrowser](/docs/usage/services/filebrowser/)** — web file browser
- **[Samba](/docs/usage/services/samba/)** — Windows/macOS file sharing
- **[NFS](/docs/usage/services/nfs/)** — Linux/Unix file sharing

Web services are reachable at `https://<service>.<your-nas>.<domain>/` on
your LAN, and `https://<service>.<your-nas>.nebula.<domain>/` over a
Nebula mesh if you've set one up — substitute the actual hostname/domain
your installation uses. Most are also reachable directly at
`http://<nas-ip>:<port>/`, bypassing the reverse proxy entirely.
