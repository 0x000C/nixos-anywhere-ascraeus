{ pkgs, ... }:
{
  services.xserver = {
    enable = true;
    layout = "us";
    libinput.enable = true;
    desktopManager.plasma6.enable = true;
    displayManager.sddm.enable = true;
  };

  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  programs = {
    kdeconnect.enable = true;
    firefox.enable = true;
  };

  environment.systemPackages = with pkgs; [
    kate
    kdePackages.konsole
  ];
}
