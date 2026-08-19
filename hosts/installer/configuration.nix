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

  # Browser-based alternative to the whiptail TUI below — see
  # hosts/installer/wizard/lib/ui-web.sh for the IPC protocol and
  # hosts/installer/wizard/lib/wiz-claim.sh for how the two are kept from
  # racing each other. Every stage_NN_*.sh file is unchanged either way;
  # only the wiz_* primitive implementation differs.
  wizWebUser = "wiz-web";
  wizRunDir = "/run/wiz-web";
  wizWebPort = 8080;

  # dashboard/static/{css,js} is the same vendored Tailwind v4 + Flowbite
  # bundle + fonts + accordion.js modules/dashboard.nix's own dashboardSite
  # uses — copied in verbatim (not via Hugo: this is fundamentally one
  # page that mutates entirely via installer.js polling /api/question,
  # not a multi-page content site, so Hugo's templating buys nothing
  # here) so the installer WebUI matches the dashboard's look and feel
  # exactly. Dashboard-specific JS (auth-nav.js, dashboard.js,
  # preferences-toggles.js — LLDAP/session-cookie coupled) is deliberately
  # NOT pulled in; none of that infrastructure exists on a live installer.
  installerWebuiSite = pkgs.runCommand "installer-webui-site" { } ''
    mkdir -p $out/css $out/js
    cp -r ${../../dashboard/static/css}/. $out/css/
    cp -r ${../../dashboard/static/js}/.  $out/js/
    cp -r ${./webui/static/css}/. $out/css/
    cp -r ${./webui/static/js}/.  $out/js/
    cp ${./webui/static/index.html} $out/index.html
  '';

  # hosts/installer/wizard/cgi/*.sh are real, standalone, directly
  # testable bash scripts (confirmed the hard way against a scripted
  # question.json/answer.json fixture before this was wired up) — read in
  # here rather than duplicated inline the way modules/dashboard-login.nix's
  # own CGIs are, since these are non-trivial enough to want a real,
  # lint-able file. writeShellApplication prepends its own shebang/`set
  # -euo pipefail`; the ones already at the top of each .sh file just
  # become harmless comments/redundant re-sets in the generated script.
  wizAnswerCgi = pkgs.writeShellApplication {
    name = "wiz-web-answer-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils ];
    text = builtins.readFile ./wizard/cgi/answer.sh;
  };
  wizInstallProgressCgi = pkgs.writeShellApplication {
    name = "wiz-web-install-progress-cgi";
    runtimeInputs = [ pkgs.jq pkgs.coreutils ];
    text = builtins.readFile ./wizard/cgi/install-progress.sh;
  };
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

  # Browser-based installer WebUI — reachable the moment this live ISO
  # finishes its own normal DHCP boot (independent of anything the wizard
  # itself does; see hosts/installer/wizard/stages/20-network.sh's own
  # comment), same as SSH already is. Coexists with the TUI below —
  # lib/wiz-claim.sh's flock decides which one actually gets to drive a
  # given boot, whichever a human answers first.
  users.users.${wizWebUser} = { isSystemUser = true; group = wizWebUser; };
  users.groups.${wizWebUser} = { };

  systemd.tmpfiles.rules = [
    # 0775, not 0770: nginx runs as its own dedicated user, in neither the
    # root nor wiz-web group, and needs to traverse this directory to
    # serve question.json/textbox-current.txt via plain `alias`
    # (confirmed the hard way against a real VM boot: 0770 gave nginx a
    # bare 403, unable to even stat into the directory). The wiz-web GROUP
    # needs write, not just read, for the same reason — the answer.sh CGI
    # (runs as user/group wiz-web) creates answer-<seq>.json files here;
    # confirmed the hard way a second time that 0755 (group read-only)
    # made that CGI fail with "Permission denied" trying to write its own
    # answer file. Nothing written here is a secret from other local
    # processes on this single-purpose live ISO; only root/wiz-web can
    # WRITE into it either way (0775 leaves "other" at r-x, not rwx).
    "d ${wizRunDir} 0775 root ${wizWebUser} - -"
  ];

  services.fcgiwrap.instances.${wizWebUser} = {
    process = {
      user = wizWebUser;
      group = wizWebUser;
    };
    socket = {
      user = config.services.nginx.user;
      group = config.services.nginx.group;
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."installer-webui" = {
      listen = [{ addr = "0.0.0.0"; port = wizWebPort; }];
      root = installerWebuiSite;
      locations = {
        # The static site (index.html/css/js) itself needs the same
        # no-cache treatment as the API endpoints below — confirmed the
        # hard way mid-session: a browser that already loaded this
        # origin once (e.g. from an earlier boot/ISO build reusing the
        # same LAN IP, which this repo's own test tooling deliberately
        # does via a pinned MAC address) will keep serving a STALE
        # cached installer.js/installer.css on later plain navigations
        # without this, silently running old frontend code against a
        # newer backend. Every boot of this ephemeral live ISO should
        # always get the exact static assets it shipped with.
        "/".extraConfig = ''
          add_header Cache-Control "no-store, must-revalidate";
        '';
        # No CGI needed at all — writes are atomic (.tmp + mv) and reads
        # never mutate anything, so a plain nginx alias is sufficient and
        # simpler than routing this through fcgiwrap.
        "= /api/question".extraConfig = ''
          alias ${wizRunDir}/question.json;
          add_header Cache-Control no-store;
        '';
        # Fixed filename (not per-request) — there's only ever one
        # blocking question at a time in this single wizard process, so
        # no per-call uniqueness is needed and this avoids any
        # path-traversal surface a dynamic path would otherwise need
        # guarding against.
        "= /api/textbox/current".extraConfig = ''
          alias ${wizRunDir}/textbox-current.txt;
          add_header Cache-Control no-store;
          default_type text/plain;
        '';
        "= /api/answer".extraConfig = ''
          fastcgi_pass unix:/run/fcgiwrap-${wizWebUser}.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe wizAnswerCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param CONTENT_TYPE $content_type;
          fastcgi_param CONTENT_LENGTH $content_length;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
        "= /api/install-progress".extraConfig = ''
          fastcgi_pass unix:/run/fcgiwrap-${wizWebUser}.sock;
          fastcgi_param SCRIPT_FILENAME ${lib.getExe wizInstallProgressCgi};
          fastcgi_param REQUEST_METHOD $request_method;
          fastcgi_param SERVER_PROTOCOL $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE nginx;
        '';
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ wizWebPort ];

  # Runs the exact same run.sh the TUI uses, just with WIZ_UI_BACKEND=web
  # (see run.sh's own dispatch) — starts unconditionally at boot, no
  # prompt, since reaching it just means opening a browser to the printed
  # URL. Restart=no is deliberate: a finished/aborted/lock-losing run
  # must not respawn a fresh $WIZ and silently re-ask everything from
  # question 1.
  systemd.services.installer-wizard-web = {
    description = "Web-driven Bearded NAS installer wizard";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "nginx.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.bash}/bin/bash /etc/nas-installer-repo/hosts/installer/wizard/run.sh";
      # A systemd service does NOT inherit the interactive login shell's
      # PATH the way environment.loginShellInit's `sudo bash run.sh`
      # does — confirmed the hard way against a real VM boot: run.sh
      # crashed instantly (exit 127) because lib/wiz-claim.sh's `flock`
      # and lib/ui-web.sh's `jq` calls resolved to nothing. Every package
      # environment.systemPackages installs (including the wizard's own
      # git/jq/zfs/curl/openssl/etc.) lands in /run/current-system/sw/bin
      # — the same PATH entry an interactive shell already gets for free.
      Environment = [ "WIZ_UI_BACKEND=web" "PATH=/run/wrappers/bin:/run/current-system/sw/bin" ];
      Restart = "no";
    };
  };

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
    # Only for an actual human at a real console or an interactive `ssh
    # root@<ip>` session (both allocate a real tty) — never for a
    # scripted, single-command `ssh root@<ip> some-command` (no tty
    # unless `-t` is forced). Without this guard every single one of
    # those non-interactive invocations still ran this whole block: its
    # banner text landed on stdout ahead of the actual command's own
    # output (silently corrupting anything that captures it, like
    # hosts/installer/wizard/test/run-vm-install.sh's disk-by-id
    # enumeration — confirmed the hard way, it counted one extra "line"
    # every time), and its `read -r -p ...` blocked on stdin until EOF,
    # at which point the empty answer fell through to the `sudo bash
    # .../run.sh` default — meaning a plain scripted health-check command
    # could unintentionally kick off a real install. Interactive-only
    # sidesteps both.
    if [ -t 0 ] && [ -t 1 ]; then
    # A bounded retry, not a one-shot `hostname -I` — this console autologin
    # fires as soon as boot reaches it, which can genuinely race DHCP still
    # completing. Confirmed the hard way against real VM boots twice: the
    # first login landed here before the interface had an address at all,
    # and a first attempt at a bounded retry (10x1s) still wasn't always
    # enough — one real boot's DHCP lease legitimately took longer than
    # that. 25x1s is a more generous margin without hanging the login
    # prompt indefinitely if the network genuinely never comes up.
    wiz_ip=""
    wiz_tries=0
    while [ "$wiz_tries" -lt 25 ]; do
      wiz_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
      [ -n "$wiz_ip" ] && break
      wiz_tries=$((wiz_tries + 1))
      sleep 1
    done
    echo "WebUI also available at: http://''${wiz_ip:-<IP once the network is up>}:${toString wizWebPort}/"
    read -r -p "Start the Bearded NAS installer? [Y/n] " start_installer
    case "$start_installer" in
      [Nn]*)
        echo "Skipping the installer — run 'sudo bash /etc/nas-installer-repo/hosts/installer/wizard/run.sh' any time to start it."
        ;;
      *)
        sudo bash /etc/nas-installer-repo/hosts/installer/wizard/run.sh
        ;;
    esac
    fi
  '';

  image.baseName = lib.mkForce "beardednas-installer";
}
