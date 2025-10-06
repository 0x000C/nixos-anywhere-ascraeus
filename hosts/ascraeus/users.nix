{ config, ... }:
let
  defaultUserPath = ../../deployment/defaults/user.nix;
  generatedUserPath = ../../deployment/generated/user.nix;
  userData = if builtins.pathExists generatedUserPath then import generatedUserPath else import defaultUserPath;
  username = userData.username;
  fullName = userData.fullName or username;
  hashedPassword = userData.hashedPassword;
  rootHashedPassword = userData.rootHashedPassword or hashedPassword;
  extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
  ensurePassword = value: if value == null then "!" else value;
  userEntry = {
    isNormalUser = true;
    description = fullName;
    inherit extraGroups;
    hashedPassword = ensurePassword hashedPassword;
    shell = config.users.defaultUserShell;
  };
in
{
  users.mutableUsers = false;
  users.users = {
    "${username}" = userEntry;
    root = {
      hashedPassword = ensurePassword rootHashedPassword;
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
}
