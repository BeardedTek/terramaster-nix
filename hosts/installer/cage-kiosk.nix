{ config, pkgs, lib, utils, ... }:

let
  kioskUser = "wiz-kiosk";

  # Loops every DRM connector across every GPU (not just card0 — a
  # multi-GPU box should still light up on whichever card actually has
  # something plugged in) and exits 0 the moment any one reads
  # "connected". Wired in as this service's own ExecCondition below, not
  # ConditionPathExists (that directive can't glob a wildcard path) or
  # ExecStartPre (a failing ExecStartPre marks the whole unit *failed*,
  # not the clean, harmless "inactive (condition-checked)" state a real
  # "no display, don't bother" no-op needs — plenty of these NAS boxes
  # are genuinely headless).
  displayDetect = pkgs.writeShellApplication {
    name = "cage-kiosk-display-detect";
    runtimeInputs = [ pkgs.coreutils pkgs.gnugrep ];
    text = ''
      shopt -s nullglob
      for status_file in /sys/class/drm/card*-*/status; do
        case "$status_file" in
          *-Writeback-*) continue ;;
        esac
        if grep -qx connected "$status_file" 2>/dev/null; then
          exit 0
        fi
      done
      exit 1
    '';
  };

  # Points at the exact same origin hosts/installer/configuration.nix's
  # own nginx already serves the WebUI installer on (wizWebPort, 8080) —
  # already fully working from any remote browser on the LAN; this is
  # just another local consumer of the identical /api/question /
  # /api/answer protocol lib/wiz-claim.sh's flock already arbitrates
  # against the TUI, so no new backend logic is needed here at all.
  kioskFirefox = pkgs.writeShellApplication {
    name = "kiosk-firefox";
    runtimeInputs = [ pkgs.firefox ];
    text = ''
      exec firefox --kiosk http://127.0.0.1:8080/
    '';
  };
in
{
  # A real, writable home is required here: NixOS system users default to
  # home = "/var/empty" with createHome = false, and Firefox needs
  # somewhere to create its profile — without this it fails fast with
  # "Your Firefox profile cannot be loaded" before ever reaching cage's
  # display.
  users.users.${kioskUser} = {
    isSystemUser = true;
    group = kioskUser;
    home = "/var/lib/${kioskUser}";
    createHome = true;
  };
  users.groups.${kioskUser} = { };

  # Firefox reads system-wide enterprise policy from this exact path on
  # Linux (no per-profile config needed). A kiosk installer has no logins
  # worth remembering and no user who should see a "Save password?"
  # doorhanger mid-wizard — disabling the password manager outright also
  # removes the prompt, rather than just suppressing the popup.
  # Value 0 is "Dark" — confirmed against Firefox's own source
  # (StaticPrefList.yaml / PreferenceSheet.cpp: 0 = Dark, 1 = Light,
  # 2 = system default), not guessed from a blog post. "default" (not
  # "locked") status matches PasswordManagerEnabled above: a real
  # preference, not an unchangeable lockdown.
  environment.etc."firefox/policies/policies.json".text = builtins.toJSON {
    policies = {
      PasswordManagerEnabled = false;
      Preferences = {
        "layout.css.prefers-color-scheme.content-override" = {
          Value = 0;
          Status = "default";
        };
      };
    };
  };

  # Mesa/DRI only — no services.xserver.videoDrivers (that's the X11 DDX
  # path; pure-Wayland KMS goes straight through Mesa) and no 32-bit/
  # VA-API packages, neither needed just to get scanout working, keeping
  # this as close to the ISO's existing minimal-profile posture as
  # possible. mkDefault (matching nixpkgs' own services.cage module)
  # rather than a hard override, so something more specific can still
  # win if ever needed.
  hardware.graphics.enable = lib.mkDefault true;

  security.polkit.enable = true;

  # Same pam_unix/pam_env/pam_systemd stack nixpkgs' own services.cage
  # module uses (nixos/modules/services/wayland/cage.nix, confirmed
  # against this flake's own pinned nixpkgs source) — pam_systemd
  # specifically is what makes systemd-logind register this service's
  # session on a real seat and grant it the udev ACL access to
  # /dev/dri/card* that a plain systemd User= alone does not confer
  # (skip this and cage/wlroots fails to open the DRM device at all,
  # "Permission denied"). Not reusing services.cage directly: it
  # hardcodes tty1, which this ISO's existing TUI autologin
  # (installation-cd-minimal.nix's own services.getty.autologinUser)
  # already owns — this copies its exact shape onto tty7 instead, so the
  # whole feature is purely additive alongside the existing tty1-6 path.
  security.pam.services.cage-kiosk = {
    useDefaultRules = false;
    rules = {
      auth = utils.pam.autoOrderRules [
        {
          name = "unix";
          control = "required";
          modulePath = "${config.security.pam.package}/lib/security/pam_unix.so";
          settings.nullok = true;
        }
      ];
      account = utils.pam.autoOrderRules [
        {
          name = "unix";
          control = "required";
          modulePath = "${config.security.pam.package}/lib/security/pam_unix.so";
        }
      ];
      session = utils.pam.autoOrderRules [
        {
          name = "unix";
          control = "required";
          modulePath = "${config.security.pam.package}/lib/security/pam_unix.so";
        }
        {
          name = "env";
          control = "required";
          modulePath = "${config.security.pam.package}/lib/security/pam_env.so";
          settings.conffile = "/etc/pam/environment";
          settings.readenv = 0;
        }
        {
          name = "systemd";
          control = "required";
          modulePath = "${config.systemd.package}/lib/security/pam_systemd.so";
        }
      ];
    };
  };

  # tty7, not tty1: installation-cd-minimal.nix's own console autologin
  # already owns tty1-6 (see hosts/installer/configuration.nix's own
  # loginShellInit comment) — this has to be a genuinely new, unclaimed
  # console for "additive, never replaces the existing TUI path" to
  # actually hold. Stays on multi-user.target — this ISO's own default —
  # rather than nixpkgs' own services.cage module convention of
  # switching the whole system's default target to graphical.target,
  # which would be a much bigger behavioral change than this needs.
  systemd.services."cage-tty7" = {
    enable = true;
    after = [
      "systemd-user-sessions.service"
      "plymouth-start.service"
      "plymouth-quit.service"
      "systemd-logind.service"
      "getty@tty7.service"
    ];
    wants = [
      "dbus.socket"
      "systemd-logind.service"
      "plymouth-quit.service"
    ];
    wantedBy = [ "multi-user.target" ];
    conflicts = [ "getty@tty7.service" ];

    restartIfChanged = false;
    unitConfig.ConditionPathExists = "/dev/tty7";
    serviceConfig = {
      # The real "is anyone actually going to see this" gate — see
      # displayDetect's own comment above for why this is ExecCondition
      # and not ConditionPathExists/ExecStartPre.
      ExecCondition = lib.getExe displayDetect;
      # Confirmed the hard way on a real VM boot: opening /dev/tty7 as a
      # controlling terminal (TTYPath below) does NOT itself switch the
      # console to that VT — tty1 stays the active/foreground one
      # (nixpkgs' own services.cage module sidesteps this entirely by
      # only ever targeting tty1, which is already active by default at
      # boot). Without an explicit switch, systemd-logind never marks
      # this session "active", and cage's own libseat/wlroots DRM
      # backend just times out after 10s waiting for that ("Timeout
      # waiting session to become active" / "Failed to start a DRM
      # session"). The "+" prefix runs this one step as root regardless
      # of this unit's own unprivileged User= below — chvt requires
      # CAP_SYS_TTY_CONFIG (or root), which wiz-kiosk deliberately
      # doesn't have.
      ExecStartPre = "+${pkgs.kbd}/bin/chvt 7";
      # -s: confirmed the hard way — cage hardcodes allow_vt_switch = false
      # unless passed this flag, and silently swallows Ctrl+Alt+Fn's
      # XF86Switch_VT_* keysym rather than calling wlr_session_change_vt()
      # (cage-kiosk/cage seat.c). Without it there's no way back to the
      # tty1-6 console/TUI while the kiosk is up — an admin needs that
      # escape hatch, and this is the one thing that grants it (the
      # existing PAMName/pam_systemd wiring above already provides the
      # logind session wlr_session_change_vt's libseat backend needs).
      ExecStart = "${pkgs.cage}/bin/cage -s -- ${lib.getExe kioskFirefox}";
      # Runs on every exit path — clean stop, crash, or ExecStart itself
      # failing to launch — so a display stays useful no matter how cage
      # goes away: tty1's own getty/autologin (already running the whole
      # time, entirely independent of this unit) is the one console
      # guaranteed to still work. Without this, a physical user watching
      # the screen is left staring at cage's last (possibly blank, per
      # TTYVTDisallocate above) frame with no visible indication that
      # switching away is even worth trying. Same root-vs-User= reasoning
      # as ExecStartPre's chvt above.
      ExecStopPost = "+${pkgs.kbd}/bin/chvt 1";
      User = kioskUser;

      IgnoreSIGPIPE = "no";
      # Log this user with utmp, letting it show up with commands 'w' and
      # 'who' — needed since this replaces (a)getty on this one tty.
      UtmpIdentifier = "%n";
      UtmpMode = "user";
      TTYPath = "/dev/tty7";
      TTYReset = "yes";
      TTYVHangup = "yes";
      TTYVTDisallocate = "yes";
      # Fail to start if not actually controlling the virtual terminal.
      StandardInput = "tty-fail";
      StandardOutput = "journal";
      StandardError = "journal";
      PAMName = "cage-kiosk";

      # Firefox's Wayland support is real in this nixpkgs pin but off by
      # default in its own wrapper — has to be forced, or it silently
      # falls back to XWayland, which isn't installed on this ISO at all.
      #
      # WLR_NO_HARDWARE_CURSORS: confirmed the hard way on a real VM boot —
      # cage rendered the WebUI correctly but the mouse cursor itself was
      # invisible. Virtualized GPUs (VirtualBox's vmwgfx here; also seen on
      # some QEMU/virtio-gpu setups) frequently lack a working hardware
      # cursor plane, which wlroots' DRM backend otherwise prefers silently.
      # This forces wlroots to composite the cursor as a regular software
      # layer instead, which works everywhere at a negligible cost on a
      # single-app kiosk. Applies to cage itself (the compositor), not
      # Firefox, but Environment= here covers the whole unit's process.
      #
      # WLR_RENDERER=pixman: also confirmed the hard way — with only
      # WLR_NO_HARDWARE_CURSORS set, the GLES2 renderer's default present
      # path on this same vmwgfx/VirtualBox setup stalled the compositor's
      # entire event loop on cursor motion (matches swaywm/sway#7066: vmwgfx
      # mishandles partial-damage buffer uploads, so software-cursor motion
      # forces a full slow re-upload per event; since it's all one event
      # loop, keyboard input — including a VT switch's own acknowledgment —
      # backs up behind it too, to the point of looking hung rather than
      # just slow). Forcing the CPU-only pixman renderer sidesteps that
      # upload path entirely. Cage only ever composites one fullscreen
      # client here (no overlapping windows, no transparency), so a
      # software blit is cheap regardless of host GPU — this is not
      # expected to be a real performance tradeoff on actual NAS hardware.
      Environment = [
        "MOZ_ENABLE_WAYLAND=1"
        "WLR_NO_HARDWARE_CURSORS=1"
        "WLR_RENDERER=pixman"
      ];
    };
  };

  # Best-effort only, not load-bearing — cage/wlroots doesn't reliably
  # honor a kernel-forced mode (confirmed against swaywm/wlroots#2040:
  # its DRM backend re-queries and can revert to its own preferred mode
  # at compositor start), and this hardware class essentially never
  # natively offers above 1080p anyway. Non-matching connector names are
  # silently ignored by the kernel, so this is zero-cost to leave in
  # rather than something worth engineering further.
  boot.kernelParams = [
    "video=eDP-1:1920x1080@60"
    "video=HDMI-A-1:1920x1080@60"
    "video=DP-1:1920x1080@60"
    "video=VGA-1:1920x1080@60"
  ];
}
