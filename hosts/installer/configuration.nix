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
    pkgs.tailscale # wizard's tailscale stage: live `tailscale up` login-link flow
    disko.packages.x86_64-linux.disko
  ];

  # Minimal — no authKeyFile/extraSetFlags (those are target-host policy,
  # modules/tailscale.nix's own concern). Just enough for tailscaled to
  # exist on this live session for the wizard's "get an auth link" flow
  # (hosts/installer/wizard/stages/66-tailscale.sh's
  # _wiz_tailscale_live_login) — 90-install.sh persists the resulting
  # authenticated /var/lib/tailscale state onto the target afterward.
  services.tailscale.enable = true;

  # Test tooling only (hosts/installer/wizard/test/run-vm-install.sh):
  # once this is running inside a VirtualBox guest, `VBoxManage
  # guestproperty get <vm> /VirtualBox/GuestInfo/Net/0/V4/IP` reports the
  # guest's real IP directly, regardless of NAT vs bridged networking —
  # replacing an earlier nmap-ping-sweep + arp-table MAC-matching
  # discovery scheme, which worked but was awkward (depended on ARP cache
  # timing, needed nmap installed on the test host, needed the VM's own
  # MAC normalized to match Windows' arp -a dash-separated format).
  # Irrelevant on real hardware — the guest-property service only ever
  # activates inside an actual VirtualBox VM in the first place.
  virtualisation.virtualbox.guest.enable = true;

  # Runs on every login (console autologin, or SSH) — see
  # hosts/installer/wizard/lib/common.sh for what it actually does.
  # Prompts first rather than launching unconditionally: installation-cd-
  # minimal.nix (imported above) auto-logs-in *every* virtual console
  # (tty1-tty6), not just tty1, so a live ISO always has spare debug
  # shells available — without this prompt, every one of those consoles
  # silently started its own independent copy of the wizard instead of
  # being a normal shell (confusing, and wasteful — e.g. Alt+F2 to check
  # `lsblk` output mid-install used to spawn a second wizard instance).
  # Defaults to yes (Enter alone accepts) since booting this ISO to
  # install is the overwhelmingly common case; explicitly typing "n"
  # drops straight to a plain shell instead, on any console or over SSH.
  # Always via sudo: installation-cd-minimal.nix's console autologin is
  # the unprivileged "nixos" user (wheel, passwordless sudo), not root —
  # confirmed the hard way (the wizard needs root for /root, mount,
  # disko, and nixos-install; running unprivileged failed on the very
  # first `rm -rf "$WIZ_REPO_WORKDIR"`, since a non-root user can't
  # even traverse into /root). A no-op when already root (SSH as root
  # via the baked-in key).
  environment.loginShellInit = ''
    read -r -p "Start the Bearded NAS installer? [Y/n] " start_installer
    case "$start_installer" in
      [Nn]*)
        echo "Skipping the installer — run 'sudo bash /etc/nas-installer-repo/hosts/installer/wizard/run.sh' any time to start it."
        ;;
      *)
        sudo bash /etc/nas-installer-repo/hosts/installer/wizard/run.sh
        ;;
    esac
  '';

  image.baseName = lib.mkForce "beardednas-installer";
}
