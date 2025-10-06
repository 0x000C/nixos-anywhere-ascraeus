{
  description = "NixOS-anywhere deployment for the Ascraeus desktop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
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
          nixos-anywhere.packages.${system}.default
          disko.packages.${system}.disko
        ];
      };
    };
}
