---
title: Jackett
linkTitle: Jackett
weight: 50
description: Proxies searches to torrent indexers that Radarr/Sonarr can't talk to directly.
---

## Information and purpose

[Jackett](https://github.com/Jackett/Jackett) translates queries from
apps like Radarr and Sonarr into indexer-specific searches, for trackers
that don't have native support built into those apps.

## Configuration

- **Access**: `https://jackett.<your-nas>.<domain>/`, the Nebula
  equivalent if configured, or directly at `http://<nas-ip>:9117/`.
- **Login**: its own separate admin password, set on first visit.
- **Consumers**: Radarr and Sonarr are pre-configured to search through
  it once you've added indexers here.

## Usage

See the [Jackett wiki](https://github.com/Jackett/Jackett/wiki/) for
adding indexers/trackers and connecting Radarr/Sonarr to them.
