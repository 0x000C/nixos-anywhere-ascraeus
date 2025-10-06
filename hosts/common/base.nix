{ lib, ... }:
{
  imports = [
    ./localisation.nix
    ./nix.nix
    ./shell.nix
  ];

  time.timeZone = "UTC";
  networking.useDHCP = lib.mkDefault true;
}
