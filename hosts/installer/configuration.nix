{ config, pkgs, lib, modulesPath, self, disko, ... }:

let
  # If the real key has already been dropped in (per docs/DEPLOYMENT.md's
  # secrets table), bake it in for convenience. If not, SSH access still
  # works the same way the stock ISO already does: `passwd` at the
  # console, then log in with that password over SSH — this environment
  # is ephemeral, so allowing that here doesn't weaken the actually
  # installed target (modules/common.nix keeps PasswordAuthentication and
  # PermitRootLogin off there, unaffected by this).
  authorizedKeyPath = ../../secrets/extra-files/home/beardedtek/.ssh/authorized_keys;
  bakedInKey = lib.optional (builtins.pathExists authorizedKeyPath) (builtins.readFile authorizedKeyPath);
in
{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  networking.hostId = "00000000";
  boot.supportedFilesystems = [ "zfs" ];
  # Never auto-force-import a hostid-mismatched pool on this live ISO —
  # the wizard's own pool-existing.sh does that deliberately, once, with
  # the operator's explicit confirmation. Leaving this at its old default
  # (true) would let systemd's own zfs-import unit force-import silently.
  boot.zfs.forceImportRoot = false;

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  users.users.root.openssh.authorizedKeys.keys = bakedInKey;

  environment.etc."nas-installer-repo".source = self;

  environment.systemPackages = [
    pkgs.newt # whiptail
    pkgs.mkpasswd
    pkgs.git
    pkgs.jq
    pkgs.zfs
    pkgs.curl # wizard's secrets stage: fetching a user's key from github.com/<user>.keys
    pkgs.openssl # 90-install.sh: generating SSO's machine-credential secrets
    # 90-install.sh's gen_oidc_client_secret: computing each confidential
    # OIDC client's argon2id secret hash offline, no network fetch needed
    # at install time — mkpasswd (above) can't do this, see that
    # function's own comment.
    pkgs.libargon2
    disko.packages.x86_64-linux.disko
  ];

  # Runs on every login (console autologin, or SSH) — see
  # hosts/installer/wizard/lib/common.sh for what it actually does.
  # Always via sudo: installation-cd-minimal.nix's console autologin is
  # the unprivileged "nixos" user (wheel, passwordless sudo), not root —
  # confirmed the hard way (the wizard needs root for /root, mount,
  # disko, and nixos-install; running unprivileged failed on the very
  # first `rm -rf "$WIZ_REPO_WORKDIR"`, since a non-root user can't
  # even traverse into /root). A no-op when already root (SSH as root
  # via the baked-in key).
  environment.loginShellInit = ''
    sudo bash /etc/nas-installer-repo/hosts/installer/wizard/run.sh
  '';

  image.baseName = lib.mkForce "beardednas-installer";
}
