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
        specialArgs = {
          beardedtekInitialHash = builtins.getEnv "BEARDEDTEK_INITIAL_HASH";
          dyoungInitialHash = builtins.getEnv "DYOUNG_INITIAL_HASH";
          rootInitialHash = builtins.getEnv "ROOT_INITIAL_HASH";
        };
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
          ./modules/traefik.nix
          ./modules/dashboard.nix
        ];
      };
    };
}
