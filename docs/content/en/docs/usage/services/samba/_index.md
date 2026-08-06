---
title: Samba
linkTitle: Samba
weight: 110
description: Windows/macOS-compatible network file shares.
---

## Information and purpose

[Samba](https://www.samba.org/) shares this box's storage over the
SMB protocol — the standard way Windows and macOS browse network drives.

## Configuration

- **Shares**: your home directory, the media library, and the
  downloads/data area are all available as separate shares; if Home
  Assistant is enabled, its config directory is shared too (see
  [Home Assistant](/docs/usage/services/home-assistant/)).
- **Login**: Samba keeps its own password, separate from your LLDAP
  password — whoever manages this box sets it for you with `smbpasswd`.
  If you don't know your Samba password, ask them.

## Usage

- **Windows**: File Explorer → address bar → `\\<your-nas>\<share>`.
- **macOS**: Finder → Go → Connect to Server → `smb://<your-nas>/<share>`.
- **Linux**: any file manager that supports `smb://<your-nas>/<share>`,
  or mount directly with `mount -t cifs`.
