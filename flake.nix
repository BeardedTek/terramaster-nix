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

      # No custom installer output: bootstrapping uses the stock NixOS
      # minimal installer ISO (nixos.org) instead — the box has a monitor
      # and keyboard attached, so a pre-baked SSH key for headless access
      # isn't needed. See docs/DEPLOYMENT.md.
    };
}
