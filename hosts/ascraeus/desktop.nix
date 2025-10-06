{ pkgs, ... }:
{
  services.xserver = {
    enable = true;
    xkb.layout = "us";
  };

  services.libinput.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;

  services.pulseaudio.enable = false;
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
    kdePackages.kate
    kdePackages.konsole
  ];
}
