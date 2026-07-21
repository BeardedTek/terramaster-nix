{ ... }:

{
  # Fresh install on nixos-26.05 — do not bump this on later upgrades, per
  # the standard NixOS stateVersion guidance (it pins on-disk data format
  # compatibility, not "which release am I running").
  system.stateVersion = "26.05";

  networking.hostName = "young";

  # Generated once for this repo with `head -c4 /dev/urandom | od -A n -t x1`.
  # Must stay stable across reinstalls of this specific host — do not
  # regenerate, and never reuse across other machines.
  networking.hostId = "975edc0d";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Root lives in RAM: nothing routine gets written to the USB flash drive.
  # /nix and /persist (below) carry everything that must survive a reboot.
  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "size=2G" "mode=755" ];
  };

  # --- `rust` pool datasets (imported, not created — see modules/zfs.nix
  # and docs/DEPLOYMENT.md for the one-time `zpool import -f rust`) ---

  # New datasets created for this install:
  fileSystems."/nix" = {
    device = "rust/nix";
    fsType = "zfs";
    neededForBoot = true;
  };
  fileSystems."/persist" = {
    device = "rust/persist";
    fsType = "zfs";
    neededForBoot = true;
  };

  # Pre-existing datasets, preserved at their current mountpoints:
  fileSystems."/home" = {
    device = "rust/home";
    fsType = "zfs";
  };
  fileSystems."/var/lib/docker" = {
    device = "rust/libdocker";
    fsType = "zfs";
  };
  fileSystems."/rust/media" = {
    device = "rust/media";
    fsType = "zfs";
  };
  fileSystems."/rust/data" = {
    device = "rust/data";
    fsType = "zfs";
  };
  fileSystems."/rust/config" = {
    device = "rust/config";
    fsType = "zfs";
  };
  fileSystems."/rust/backups" = {
    device = "rust/backups";
    fsType = "zfs";
  };
  fileSystems."/rust/docker" = {
    device = "rust/docker";
    fsType = "zfs";
  };

  # Files/dirs that must survive the tmpfs root across reboots.
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos" # NixOS's dynamic uid/gid allocation state for
                        # normal users + system users (jellyfin, sshd,
                        # seerr, etc.) — without this, every reboot would
                        # reassign UIDs/GIDs, silently breaking ownership
                        # on every ZFS-backed path (/home, /rust/*, ...).
      "/etc/nebula"
      "/var/lib/samba"
      "/etc/ssh"
      "/var/lib/jellyfin"
      "/var/lib/sonarr"
      "/var/lib/radarr"
      "/var/lib/jackett"
      "/var/lib/seerr"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  users.mutableUsers = false;

  # NixOS's build-time "you'll be locked out" assertion can't see the real
  # SSH key (it's delivered out-of-band, not through this config — see
  # below), so it needs to be told explicitly that this is intentional.
  users.allowNoPasswordLogin = true;

  # No openssh.authorizedKeys.keys here on purpose: the real public key
  # isn't committed to this repo at all. It's delivered straight to
  # /home/beardedtek/.ssh/authorized_keys via
  # `nixos-anywhere --extra-files ./secrets/extra-files` (see
  # docs/DEPLOYMENT.md) — /home is the real rust/home ZFS dataset, not the
  # tmpfs root, so it persists across reboots without needing an
  # environment.persistence entry.
  users.users.beardedtek = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  users.users.dyoung = {
    isNormalUser = true;
    # No `wheel` — share access only, no sudo.
  };

  security.sudo.wheelNeedsPassword = true;
}
