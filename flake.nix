{
  description = "NixOS-anywhere deployment for the Ascraeus desktop";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    disko.url = "github:nix-community/disko";
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
  };

  outputs = inputs@{ self, nixpkgs, disko, nixos-anywhere, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations.ascraeus = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/ascraeus
          disko.nixosModules.disko
          { nixpkgs.hostPlatform = system; }
        ];
      };

      formatter.${system} = pkgs.nixpkgs-fmt;

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.git
          pkgs.cachix
          nixos-anywhere.packages.${system}.default
          disko.packages.${system}.disko
        ];
      };
    };
}
