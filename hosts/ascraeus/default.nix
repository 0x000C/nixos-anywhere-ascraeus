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
  ];

  system.stateVersion = lib.mkDefault "23.11";
}
