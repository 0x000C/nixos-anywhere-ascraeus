{ config, lib, pkgs, ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
      };
    };
    initrd = {
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" ];
      luks.devices.cryptroot = {
        device = "/dev/disk/by-partlabel/cryptroot";
        preLVM = true;
        allowDiscards = true;
      };
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [];
  };

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
