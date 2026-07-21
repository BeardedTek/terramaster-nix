# terramaster-nix

NixOS flake for `young`, a TerraMaster F4-245 NAS (4x6TB HDDs in an existing
ZFS `rust` RAIDZ1 pool, 256GB internal USB as a tmpfs-root system drive).
Deployed via disko + nixos-anywhere.

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for the full install workflow
and a list of `CHANGEME` placeholders that need real values before deploying.