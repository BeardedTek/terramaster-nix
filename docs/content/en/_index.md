---
title: Bearded NAS
description: A self-hosted NixOS flake for TerraMaster-family NAS hardware
params:
  body_class: td-navbar-links-all-active
---

{{% blocks/cover title="Bearded NAS" height="full td-below-navbar" image_anchor="top" color="dark" %}}

<img src="/logo.svg" alt="Bearded NAS" class="hero-logo mb-4" />

{{% param "description" %}}
{.display-6}

<a class="btn btn-lg btn-primary me-3 mb-4" href="/docs/">
  Documentation <i class="fa-solid fa-book ms-2"></i>
</a>
<a class="btn btn-lg btn-primary me-3 mb-4" href="https://github.com/BeardedTek/terramaster-nix/releases">
  Download installer ISO <i class="fa-solid fa-compact-disc ms-2"></i>
</a>
<a class="btn btn-lg btn-secondary me-3 mb-4" href="https://github.com/BeardedTek/terramaster-nix">
  Get the code <i class="fab fa-github ms-2"></i>
</a>

{{% blocks/link-down color="info" %}}

{{% /blocks/cover %}}

{{% blocks/lead color="white" %}}

**Bearded NAS** turns a Low Powered NAS appliance into a fully declarative
NixOS box: ZFS storage (adopt an existing pool or create a new one),
Samba/NFS file sharing, a Jellyfin + \*arr media stack, Home Assistant,
Frigate NVR, and Traefik-fronted access over both the LAN and a Nebula
mesh — all defined in one flake, with a self-contained installer wizard
to bring a new box up from blank disks.

{{% /blocks/lead %}}

{{% blocks/section color="primary" type="row" %}}

{{% blocks/feature title="Declarative storage" icon="fa-solid fa-server" url="/docs/architecture/" %}}

ZFS pool creation or adoption, tmpfs root to spare the boot drive, and
`impermanence`-backed persistence — see the
[architecture doc](/docs/architecture/) for the full design.

{{% /blocks/feature %}}

{{% blocks/feature title="Self-contained installer" icon="fa-solid fa-compact-disc" url="/docs/installer/" %}}

A bootable ISO with a TUI wizard that partitions disks, collects users
and settings, and runs `nixos-install` itself — no separate workstation
required. Pre-built for every
[release](https://github.com/BeardedTek/terramaster-nix/releases), or
[see the docs](/docs/installer/) to build your own.

{{% /blocks/feature %}}

{{% blocks/feature title="Media & home automation" icon="fa-solid fa-house-signal" url="/docs/home-assistant/" %}}

Jellyfin, Sonarr, Radarr, Jackett, Seerr, Home Assistant, and Frigate,
proxied through Traefik on both the LAN and a Nebula mesh.

{{% /blocks/feature %}}

{{% /blocks/section %}}

{{% blocks/section color="white" type="row" %}}

{{% blocks/feature title="One file to configure" icon="fa-solid fa-sliders" url="/docs/architecture/" %}}

`variables.nix` is the single place to set hostname, users, contact info,
and which services are enabled — see the
[architecture doc](/docs/architecture/).

{{% /blocks/feature %}}

{{% blocks/feature title="Open source" icon="fab fa-github" url="https://github.com/BeardedTek/terramaster-nix" %}}

The whole flake — modules, the installer wizard, and this documentation
site — is open source. Issues and PRs welcome.

{{% /blocks/feature %}}

{{% blocks/feature title="Built on NixOS" icon="fa-solid fa-snowflake" url="https://nixos.org" %}}

Every service is a native NixOS module or a small, well-documented piece
of glue around one — no Docker Compose sprawl to maintain.

{{% /blocks/feature %}}

{{% /blocks/section %}}
