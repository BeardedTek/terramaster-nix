---
title: NFS
linkTitle: NFS
weight: 120
description: Linux/Unix-native network file shares.
---

## Information and purpose

NFS (Network File System, v4) shares this box's storage the native way
for Linux and Unix-like systems — generally faster and simpler than SMB
between Linux machines, since there's no protocol translation involved.

## Configuration

- **Exports**: the media library and downloads/data area are exported
  over NFS. Access is granted by network, not by username/password — any
  device on the same LAN (or connected mesh, if one is set up) can mount
  them, so there's nothing to log into.

## Usage

From a Linux client:

```sh
sudo mkdir -p /mnt/nas-media
sudo mount -t nfs <your-nas>:/rust/media /mnt/nas-media
```

Add an entry to `/etc/fstab` if you want it mounted automatically at
boot. See `man mount.nfs` for mount options.
