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
          ./hosts/terramaster/f4-245/disko.nix
          ./hosts/terramaster/f4-245/configuration.nix
          ./variables.nix
          ./modules/common.nix
          ./modules/users.nix
          ./modules/zfs.nix
          ./modules/samba.nix
          ./modules/nfs.nix
          ./modules/media-stack.nix
          ./modules/nebula.nix
          ./modules/traefik.nix
          ./modules/dashboard.nix
          ./modules/frigate.nix
          ./modules/home-assistant.nix
        ];
      };
    };
}
