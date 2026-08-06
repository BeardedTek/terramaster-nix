---
title: FileBrowser
linkTitle: FileBrowser
weight: 100
description: Browse and manage files over the web.
---

## Information and purpose

A web-based file browser over this box's media library and downloads/data
area — upload, download, rename, and organize files from a browser
without needing a Samba/NFS client set up.

## Configuration

- **Access**: `https://files.<your-nas>.<domain>/`, the Nebula equivalent
  if configured, or directly at `http://<nas-ip>:8095/`.
- **Login**: its own separate admin account, set up by whoever manages
  this box during install.
- **Sources**: shows the media library and data/downloads area as two
  separate top-level sections — not the whole storage pool, so
  unrelated system folders aren't browsable.

## Usage

Built on [FileBrowser Quantum](https://github.com/gtsteffaniak/filebrowser)
— see that project's README for feature details (file previews, sharing
links, and multi-source browsing).
