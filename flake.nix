{
  description = "Bearded NAS — NixOS configuration for one or more Bearded NAS hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, disko, impermanence, ... }:
    let
      inherit (nixpkgs) lib;
      system = "x86_64-linux";

      # variables.nix is gitignored (see variables.nix.example) — each
      # host's own copy is local-only and never committed. Inside an
      # actual git repository, that means Nix's own git-tree-filtered
      # resolution of `.`/`self` can never see it through a normal
      # self-relative path: confirmed the hard way earlier (a brand-new,
      # not-yet-`git add`ed host directory was completely invisible to
      # `nix eval`, even with --impure — flakes filter local `.` sources
      # down to tracked files regardless of purity settings). repoRoot
      # reads it through a real absolute filesystem path instead,
      # sidestepping that filtering — the same trick every /persist/...
      # read elsewhere in this repo already relies on.
      #
      # This is only ever *needed* as a fallback (see variablesFileFor
      # below): the wizard's own scratch checkouts
      # (hosts/installer/wizard/lib/common.sh's WIZ_REPO_WORKDIR, used by
      # both the installer itself and run-config-check.sh's Tier 1 test)
      # are a plain `cp -rL`/no-`.git` copy in the common case, where
      # nothing is filtered at all and the ordinary self-relative path
      # already works — laziness means repoRoot, and its PWD requirement,
      # is never forced there. It's only forced for a real git checkout
      # (this dev repo, or a `git clone`d scratch one) — and only
      # correct when invoked from that checkout's own root, which is
      # already the convention every command in this repo's docs follows.
      repoRoot =
        let pwd = builtins.getEnv "PWD"; in
        if pwd != "" then /. + pwd else throw "flake.nix: variables.nix isn't visible through the normal (git-filtered) path here, and $PWD is unset so the absolute-path fallback can't run either — invoke nix build/eval from this repo's own root.";

      # Every host lives at hosts/<manufacturer>/<instance>/ with its own
      # variables.nix + configuration.nix + disko.nix — discovered here
      # instead of reading one top-level variables.nix, so this repo can
      # carry configs for multiple real machines (e.g. young, metis) at
      # once and build any of them via `nixos-rebuild --flake .#<hostname>`
      # from the exact same checkout, no swapping files around. hosts/
      # installer/ sits at the same depth as a manufacturer dir but has no
      # instance subdirs containing their own variables.nix, so it's
      # naturally skipped by the pathExists filter below rather than
      # needing an explicit exclusion.
      manufacturerNames = builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
      );
      instanceDirsFor = manufacturer:
        let
          base = ./hosts + "/${manufacturer}";
          instanceNames = builtins.attrNames (
            lib.filterAttrs (_: type: type == "directory") (builtins.readDir base)
          );
        in
        map
          (instance: {
            # configuration.nix/disko.nix ARE committed, so the normal
            # self-relative (git-filtered) path is fine — and preferred,
            # keeping them pinned to this exact flake revision like every
            # other module here.
            relDir = base + "/${instance}";
            # variables.nix is not committed: try the plain self-relative
            # path first (correct and PWD-independent whenever nothing's
            # actually being filtered — see repoRoot's comment), only
            # falling back to the absolute-path read if that's genuinely
            # not visible.
            relVariablesFile = base + "/${instance}/variables.nix";
            absVariablesFile = repoRoot + "/hosts/${manufacturer}/${instance}/variables.nix";
          })
          instanceNames;
      allHosts = lib.concatMap instanceDirsFor manufacturerNames;
      variablesFileFor = h: if builtins.pathExists h.relVariablesFile then h.relVariablesFile else h.absVariablesFile;
      hosts = builtins.filter (h: builtins.pathExists (variablesFileFor h)) allHosts;

      # Same shape, for modules/dashboard-network.nix's DHCP/Static IP
      # toggle.
      networkOverridesPath = /persist/nixos-network-overrides.nix;
      # Same shape, for modules/dashboard-smtp.nix's SMTP relay settings
      # (forces mySystem.smtp as a whole — the password itself lives in
      # /persist/etc/opensmtpd/secrets, not here).
      smtpOverridesPath = /persist/nixos-smtp-overrides.nix;
      # Same shape, for modules/dashboard-svcconfig.nix's Authelia theme
      # setting (the only Service Configuration field that needs a
      # rebuild — MinIO's root credentials are a plain runtime file, no
      # overrides path needed for those).
      autheliaOverridesPath = /persist/nixos-authelia-overrides.nix;
      # Same shape, for modules/dashboard-svcconfig.nix's Vaultwarden
      # signupsAllowed setting.
      vaultwardenOverridesPath = /persist/nixos-vaultwarden-overrides.nix;
      # Same shape, for modules/dashboard-svcconfig.nix's Tailscale
      # acceptDns/acceptRoutes/advertiseExitNode/advertiseRoutes
      # settings.
      tailscaleOverridesPath = /persist/nixos-tailscale-overrides.nix;
      # Same shape, for modules/dashboard-svcconfig.nix's Immich
      # machine-learning and public-proxy toggles.
      immichMlOverridesPath = /persist/nixos-immich-ml-overrides.nix;
      immichProxyOverridesPath = /persist/nixos-immich-proxy-overrides.nix;
      # Same shape, for modules/dashboard-svcconfig.nix's 21 absorbed
      # service enable/disable flags (formerly
      # modules/dashboard-services.nix's own serviceOverridesPath,
      # before the "Services" accordion on System Preferences was
      # merged into each service's own Service Configuration panel).
      serviceEnableOverridesPath = /persist/nixos-service-enable-overrides.nix;
      # Attribute name follows each host's own variables.nix hostName
      # rather than being hardcoded — a differently-named instance (e.g.
      # one freshly generated by hosts/installer/wizard, which writes its
      # own variables.nix into its host_dir) gets a matching
      # `nixosConfigurations.<hostname>` automatically, with no flake.nix
      # edit needed, as long as its directory is present in this checkout.
      mkHostConfig = host:
        let variablesFile = variablesFileFor host; in
        {
          name = (import variablesFile).networking.hostName;
          value = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              disko.nixosModules.disko
              impermanence.nixosModules.impermanence
              (host.relDir + "/disko.nix")
              (host.relDir + "/configuration.nix")
              variablesFile
              ./modules/common.nix
              ./modules/users.nix
              ./modules/zfs.nix
              ./modules/samba.nix
              ./modules/nfs.nix
              ./modules/media-stack.nix
              ./modules/nebula.nix
              ./modules/traefik.nix
              ./modules/traefik-dns01.nix
              ./modules/dashboard.nix
              ./modules/dashboard-network.nix
              ./modules/dashboard-smtp.nix
              ./modules/dashboard-nebula.nix
              ./modules/dashboard-svcconfig.nix
              ./modules/vaultwarden.nix
              ./modules/scrutiny.nix
              ./modules/plex.nix
              ./modules/immich.nix
              ./modules/tailscale.nix
              ./modules/dashboard-tailscale.nix
              ./modules/system-rebuild.nix
              ./modules/frigate.nix
              ./modules/home-assistant.nix
              ./modules/minio.nix
              ./modules/filebrowser.nix
              ./modules/self-update.nix
              ./modules/lldap.nix
              ./modules/authelia.nix
              ./modules/smtp-relay.nix
              ./modules/dashboard-login.nix
              ./modules/unix-ldap-login.nix
            ] ++ (if builtins.pathExists networkOverridesPath then [ networkOverridesPath ] else [ ])
              ++ (if builtins.pathExists smtpOverridesPath then [ smtpOverridesPath ] else [ ])
              ++ (if builtins.pathExists autheliaOverridesPath then [ autheliaOverridesPath ] else [ ])
              ++ (if builtins.pathExists vaultwardenOverridesPath then [ vaultwardenOverridesPath ] else [ ])
              ++ (if builtins.pathExists tailscaleOverridesPath then [ tailscaleOverridesPath ] else [ ])
              ++ (if builtins.pathExists immichMlOverridesPath then [ immichMlOverridesPath ] else [ ])
              ++ (if builtins.pathExists immichProxyOverridesPath then [ immichProxyOverridesPath ] else [ ])
              ++ (if builtins.pathExists serviceEnableOverridesPath then [ serviceEnableOverridesPath ] else [ ]);
          };
        };
    in
    {
      nixosConfigurations = (builtins.listToAttrs (map mkHostConfig hosts)) // {
        installer = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit self disko; };
          modules = [
            disko.nixosModules.disko
            ./hosts/installer/configuration.nix
          ];
        };
      };
    };
}
