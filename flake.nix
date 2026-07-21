{
  description = "NixOS configuration for young (TerraMaster F4-245 NAS)";

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
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.young = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          ./hosts/young/disko.nix
          ./hosts/young/configuration.nix
          ./modules/common.nix
          ./modules/zfs.nix
          ./modules/samba.nix
          ./modules/nfs.nix
          ./modules/media-stack.nix
          ./modules/nebula.nix
        ];
      };

      # Custom SSH-enabled live installer ISO used to bootstrap `young` via
      # nixos-anywhere (see hosts/installer/configuration.nix for why this
      # exists instead of the stock ISO).
      #
      # The authorizing SSH key is read from $INSTALLER_SSH_KEY at build
      # time via builtins.getEnv (requires `nix build --impure`), rather
      # than being committed to this file or read from a gitignored path
      # inside the flake — the latter wouldn't work anyway, since a local
      # flake's source is filtered to git-tracked files, silently omitting
      # anything gitignored. Build with:
      #   INSTALLER_SSH_KEY="$(cat secrets/extra-files/home/beardedtek/.ssh/authorized_keys)" \
      #     nix build --impure .#nixosConfigurations.installer.config.system.build.isoImage
      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { installerSshKey = builtins.getEnv "INSTALLER_SSH_KEY"; };
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./hosts/installer/configuration.nix
        ];
      };
    };
}
