# Bearded NAS

NixOS flake for `young`, a TerraMaster F4-245 NAS (4x6TB HDDs in an existing
ZFS `rust` RAIDZ1 pool, 256GB internal USB as a tmpfs-root system drive).
Deployed via disko + nixos-anywhere, with a self-contained installer ISO
for provisioning additional boxes.

Full documentation site: [docs/](docs/) (Hugo + Docsy — run `hugo server`
inside `docs/` for a local preview, or see the built site once it's
deployed). Start with:

- **[Architecture](docs/content/en/docs/architecture/_index.md)** —
  design rationale: storage layout, persistence strategy, users,
  networking, and what each service module does and why.
- **[Deployment](docs/content/en/docs/deployment/_index.md)** —
  the full install workflow and a list of `CHANGEME` placeholders that
  need real values before deploying.
- **[Installer ISO](docs/content/en/docs/installer/_index.md)** —
  the self-contained installer ISO: a TUI wizard for provisioning a *new*
  NAS (blank disks or an existing pool to adopt), building/flashing it,
  and what it automates.
- **[Home Assistant](docs/content/en/docs/home-assistant/_index.md)** —
  HACS, Z-Wave JS, Mosquitto, the config-directory Samba share, and how to
  extend it further.
- **[Troubleshooting](docs/content/en/docs/troubleshooting/_index.md)** —
  known failure modes and their fixes, organized by symptom.
