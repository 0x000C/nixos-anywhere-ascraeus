{ lib, ... }:
{
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
  };

  services.thermald.enable = lib.mkDefault true;

  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "schedutil";
  };

  services.fstrim.enable = true;
}
