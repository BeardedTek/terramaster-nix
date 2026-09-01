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

### Pre-loading secrets — no second USB drive needed

The published image already carries a second, empty partition labeled
`NAS-SECRETS` right alongside the bootable installer, on the very same
file — no separate drive, no command-line tooling, no WSL. After
flashing, that USB stick shows up as **two** volumes when plugged into
any everyday computer: the boot volume, and a plain removable
`NAS-SECRETS` drive you can open in Explorer/Finder/any file manager and
drop files onto directly, before booting the NAS from it. The layout the
wizard's Secrets step (below) looks for:

```
authorized_keys           # first user's SSH public key(s)
etc/nebula/config.yaml    # Nebula mesh config (+ certs alongside)
etc/traefik/traefik.env   # Traefik DNS-01 provider credentials
etc/minio/minio.env       # MinIO root credentials
```

All of it is optional — anything you leave out just falls back to the
interactive prompt or a generated placeholder, same as always.

For a fully hands-off image with secrets already baked in (so there's
nothing to drag-and-drop after flashing): populate
`secrets/nas-secrets-usb/` in your own checkout (see the `*.example`
templates there for the exact layout) and build it yourself —
`nix build --impure .#packages.x86_64-linux.installer-iso` — instead of
downloading the generic release image.

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
7. **Secrets** — how the first user gets SSH access. Looks for a drive
   labeled `NAS-SECRETS` first (see "Pre-loading secrets" above — this
   can be a partition on the boot USB itself or a separate drive); if
   none is found, offers to fetch a public key from a GitHub username,
   paste one directly, or fall back to password-based SSH login (off by
   default everywhere else — the wizard warns before enabling it).
8. **Review** — a full summary, then a confirmation before anything
   destructive happens.
9. **Install** — writes the configuration, sets up storage, and installs
   the system.

## Walkthrough (WebUI)

The TUI and the WebUI ask exactly the same questions — these screenshots are
from the WebUI, reachable from any other device's browser at the IP address
the console prints on boot.

![Welcome screen](/images/installer/01-welcome.png)
Welcome screen — explains the two storage paths up front.

![LAN interface picker](/images/installer/03-network.png)
Pick the LAN interface.

![Storage path choice](/images/installer/09-storage-choice.png)
Storage: adopt an existing pool, or create a new one from blank disks.

![Existing-data confirmation](/images/installer/12-confirm-existing-data.png)
Any disk flagged with existing data needs its own explicit confirmation
before it can join a new pool.

![Generated disko.nix preview](/images/installer/15-disko-preview.png)
The exact generated `disko.nix` is shown before anything is written.

![Services checklist](/images/installer/19-services.png)
Services checklist — pick what runs on this box.

![Review screen](/images/installer/25-review.png)
Full review of every answer before the destructive confirmation screen.

![Type DESTROY to confirm](/images/installer/26-confirm-destroy.png)
Creating a new pool requires typing `DESTROY` — no accidental data loss.

![Installing progress](/images/installer/27-installing.png)
Unattended from here — writes the config, partitions storage, and installs
NixOS, with a live log available the whole way through.

![Install done](/images/installer/28-done.png)
Done — where the generated config ends up, and what to do with it.

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
