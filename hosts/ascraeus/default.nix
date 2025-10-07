{ lib, ... }:
{
  imports = [
    ../common/base.nix
    ./hardware.nix
    ./storage.nix
    ./networking.nix
    ./desktop.nix
    ./users.nix
    ./services.nix
    ./performance.nix
    ./secrets.nix
  ];

  system.stateVersion = lib.mkDefault "25.05";
}
