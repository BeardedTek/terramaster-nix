---
title: ISO Installation
linkTitle: ISO Installation
weight: 10
description: The default, guided way to install Bearded NAS — a bootable ISO with a TUI wizard.
---

The default way to install: a bootable ISO with a TUI wizard that
partitions disks, collects your users and settings, and installs the
system itself — no separate workstation required.

## Download

Every tagged release publishes a ready-to-flash ISO — grab the latest from
[GitHub Releases](https://github.com/BeardedTek/terramaster-nix/releases),
no build step required.

Flash it to a USB drive the same way as any Linux ISO
(`dd if=<file>.iso of=/dev/sdX bs=4M status=progress` from another Linux
machine, or Rufus/balenaEtcher on Windows/macOS), then boot your NAS from
it.

## What the wizard does

Boots to a TUI (also reachable over SSH if you'd rather drive it
remotely) that walks through, in order:

1. **Repo freshness** — offers to pull a fresh copy of the config before
   generating anything, in case the ISO is older than the latest release.
2. **Network** — pick the LAN interface.
3. **Instance identity** — hostname and a name for this specific machine.
4. **Storage** — the decision covered on the
   [Installation overview](/docs/installation/) page: adopt an existing
   pool, or create a new one from blank drives.
5. **Users** — add each user (name, admin/sudo or not, password).
6. **Services** — a checklist of everything covered on the
   [Available Services](/docs/usage/services/) page: pick what you want
   running.
7. **Secrets** — how the first user gets SSH access. Looks for a USB
   drive labeled `NAS-SECRETS` first; if none is found, offers to fetch a
   public key from a GitHub username, paste one directly, or fall back to
   password-based SSH login (off by default everywhere else — the wizard
   warns before enabling it).
8. **Review** — a full summary, then a confirmation before anything
   destructive happens.
9. **Install** — writes the configuration, sets up storage, and installs
   the system.

## After it finishes

The files the wizard generated (your new host's configuration) are copied
to a location on the installed system — retrieve them and commit them
into your own copy of the repo, since the wizard doesn't push to git
itself. This is what lets you rebuild or update this exact box later from
a workstation.

## What this doesn't do (yet)

- No unattended/non-interactive mode — every run is interactive.
- Can't paste a full Nebula mesh config through the wizard yet; set that
  up manually after first boot if you want remote access over the mesh.

## Resource requirements

Unlike installing from a workstation, this wizard builds the entire
system locally, on the NAS hardware itself — which needs real network
access during install (to fetch packages) and enough RAM to complete the
build. Budget at least 8GB RAM for the install step if you're enabling
most services; a lower-RAM machine may need fewer services enabled for
the initial install (you can always turn more on afterward).
