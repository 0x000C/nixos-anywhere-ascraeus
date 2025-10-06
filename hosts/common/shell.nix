{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    wget
    vim
  ];

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
}
