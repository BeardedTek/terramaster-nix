# terramaster-nix

NixOS flake for `young`, a TerraMaster F4-245 NAS (4x6TB HDDs in an existing
ZFS `rust` RAIDZ1 pool, 256GB internal USB as a tmpfs-root system drive).
Deployed via disko + nixos-anywhere.

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for the full install workflow
and a list of `CHANGEME` placeholders that need real values before deploying.

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — design rationale: storage
  layout, persistence strategy, users, networking, and what each service
  module does and why.
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) — known failure modes
  and their fixes, organized by symptom.
- [docs/HOME-ASSISTANT.md](docs/HOME-ASSISTANT.md) — Home Assistant setup:
  HACS, Z-Wave JS, Mosquitto, the config-directory Samba share, and how to
  extend it further.
- [docs/INSTALLER.md](docs/INSTALLER.md) — the self-contained installer
  ISO: a TUI wizard for provisioning a *new* NAS (blank disks or an
  existing pool to adopt), building/flashing it, and what it automates.