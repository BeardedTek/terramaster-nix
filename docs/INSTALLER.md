# Installer ISO

A self-contained, bootable installer for provisioning a new NAS under
this flake — a TUI wizard walks through networking, storage, users, and
which services to enable, then installs NixOS itself. No separate
workstation orchestration needed (unlike `docs/DEPLOYMENT.md`'s
`nixos-anywhere`-driven flow, which remains the documented path for
`young` specifically, and as the manual reference for what this wizard
automates).

## Building the ISO

```sh
nix build --impure '.#nixosConfigurations.installer.config.system.build.isoImage'
```

The result (`result/iso/*.iso`) has a full copy of this repo baked in as
of build time — see "Repo freshness" below for what that means in
practice. If `secrets/extra-files/home/beardedtek/.ssh/authorized_keys`
exists locally when you build, it's baked into the ISO's `root` account
too, for convenience; if not, the wizard falls back to the same
`passwd`-then-SSH dance `docs/DEPLOYMENT.md` step 2 already documents for
the stock ISO.

Flash the result to a USB drive the same way as any NixOS ISO
(`dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress` from another
Linux machine, or Rufus/balenaEtcher on Windows/macOS).

## What the wizard does

Boots to a TUI (also reachable over SSH — `ssh root@<installer-ip>`, key
or temporary password per above) that walks through, in order:

1. **Repo freshness** — offers to `git clone` a fresh copy from GitHub
   before generating anything, in case the ISO is older than the repo.
   Falls back to the baked-in copy if there's no network or the clone
   fails — nothing is lost either way.
2. **Network** — pick the LAN interface.
3. **Instance identity** — manufacturer, instance name (becomes
   `hosts/<manufacturer>/<instance>/`), hostname, ZFS hostid.
4. **Storage** — the one genuinely consequential choice:
   - **Adopt an existing pool**: non-destructive. Imports the pool,
     fixes every existing dataset's `mountpoint` property to `legacy`
     (metadata-only — see `docs/ARCHITECTURE.md`'s "every dataset must be
     `mountpoint=legacy`" explanation), creates `nix`/`persist` datasets
     if they're missing, and asks which existing datasets to use for
     `home`/`media`/`data`. This is exactly `docs/DEPLOYMENT.md` step 3,
     automated and generalized to any pool's actual dataset list instead
     of a hardcoded one.
   - **Create a new pool**: destructive. Disk discovery flags any disk
     with an existing filesystem/RAID/ZFS signature and excludes it from
     the pool by default — including one requires an explicit
     per-disk confirmation. Uses `lib/zfs-pool.nix` (the same function
     `hosts/terramaster/f4-245/`'s template uses) to generate a real
     `disko.nix`, shown in full before you're asked to type `DESTROY`
     (not just click yes/no) to actually run it.
5. **Users** — add each user (name, sudo or not, password — hashed
   locally with `mkpasswd -m sha-512`; plaintext never touches disk).
6. **Services** — a checklist matching `mySystem.features`' exact shape
   (`modules/common.nix`).
7. **Secrets** — an SSH public key is required (no password-based SSH on
   the *installed* system). Looks for a USB drive labeled `NAS-SECRETS`
   (its own flat layout — `authorized_keys`, `etc/nebula/config.yaml`,
   `etc/traefik/traefik.env` — not `docs/DEPLOYMENT.md`'s
   `secrets/extra-files/` tree, which is nested under a hardcoded
   `beardedtek` username that doesn't generalize to a wizard-chosen admin
   user) for `authorized_keys` and (optionally) Nebula/Traefik secrets; falls
   back to pasting the SSH key directly and skipping Nebula/Traefik for
   now (those just need manual setup post-install, same as leaving
   `CHANGEME` placeholders unfilled today).
8. **Review** — full summary, then the destructive-path confirmation
   described above (new pool) or a plain yes/no (existing pool, since
   nothing on that path deletes data).
9. **Install** — writes `variables.nix`, `hosts/<manufacturer>/<instance>/{disko.nix,configuration.nix}`,
   and `secrets/initial-passwords.env` into its working checkout, runs
   the actual storage setup, then `nixos-install`.

## After it finishes

The generated files are copied to `/persist/nixos-installer-output/` on
the newly installed system — retrieve them (`scp` or the Samba share) and
commit them into your own git checkout of this repo. The wizard never
pushes to git itself. `secrets/initial-passwords.env` is deliberately
*not* included in that copy (it only mattered for this one install);
recreate it locally from `secrets/initial-passwords.env.example` if
you'll be rebuilding this box from a workstation later, per
`docs/DEPLOYMENT.md`.

## What this doesn't do (yet)

- No unattended/non-interactive mode — every run is interactive.
- Pasting a full Nebula config through the wizard isn't implemented; use
  a `NAS-SECRETS` USB drive or configure it manually after first boot.
- Only tested by generating config against fake wizard state and
  validating the result with `nix eval`/`nix build` (see this repo's
  session history) plus a `qemu` boot smoke test — not yet run against
  real hardware. Treat the first real run as a trial, not a guarantee.
