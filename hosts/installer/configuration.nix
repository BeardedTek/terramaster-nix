{ pkgs, lib, installerSshKey, ... }:

{
  # Custom SSH-enabled live installer, used instead of the stock ISO because
  # community reports suggest the F4-245's internal USB header only boots
  # TerraMaster's own TOS install stub, not a general-purpose live OS. Flash
  # this to a *separate* external USB drive and boot the box from that one
  # instead (see docs/DEPLOYMENT.md) — the internal 256GB drive is only ever
  # touched remotely, as the nixos-anywhere/disko install target.

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  networking.hostName = "young-installer";
  # No explicit networking.useDHCP: the base installer profile
  # (installation-cd-minimal.nix) already enables NetworkManager, which
  # manages DHCP itself and conflicts with setting this directly.

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Populated from $INSTALLER_SSH_KEY at build time (see flake.nix) — empty
  # unless the build was invoked with that env var set, so a plain
  # `nix build` without it produces a locked-out (harmless, just useless)
  # ISO rather than one with a hardcoded key.
  users.users.root.openssh.authorizedKeys.keys =
    lib.optional (installerSshKey != "") installerSshKey;

  environment.systemPackages = with pkgs; [
    parted
    zfs
  ];
}
