{ pkgs, ... }:
{
  services.printing.enable = true;
  services.blueman.enable = true;

  hardware.bluetooth.enable = true;

  services.flatpak.enable = true;

  systemd.services.nix-daemon.serviceConfig.LimitNOFILE = 1048576;

  environment.systemPackages = with pkgs; [
    htop
    nvtopPackages.full
  ];
}
