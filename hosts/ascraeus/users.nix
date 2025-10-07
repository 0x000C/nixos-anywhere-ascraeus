{ config, lib, ... }:
let
  defaultUserPath = ../../deployment/defaults/user.nix;
  defaultUser = import defaultUserPath;
  username = defaultUser.username;
  fullName = defaultUser.fullName or username;
  hashedPasswordDefault = defaultUser.hashedPassword;
  rootHashedPasswordDefault = defaultUser.rootHashedPassword or hashedPasswordDefault;
  extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
  ensurePassword = value: if value == null then "!" else value;
  secretsFile = ../../secrets/ascraeus.secrets.json;
  hasSecrets = builtins.pathExists secretsFile;
  userPasswordSecretName = "users/${username}/password";
  rootPasswordSecretName = "users/root-password";
in {
  sops.secrets = lib.mkIf hasSecrets {
    "${userPasswordSecretName}" = {
      sopsFile = secretsFile;
      format = "json";
      key = "users.${username}.hashedPassword";
      owner = "root";
      mode = "0400";
    };
    "${rootPasswordSecretName}" = {
      sopsFile = secretsFile;
      format = "json";
      key = "users.root.hashedPassword";
      owner = "root";
      mode = "0400";
    };
  };

  users.mutableUsers = false;

  users.users = {
    "${username}" = lib.mkMerge [
      {
        isNormalUser = true;
        description = fullName;
        inherit extraGroups;
        hashedPassword = ensurePassword hashedPasswordDefault;
        shell = config.users.defaultUserShell;
      }
      (lib.mkIf hasSecrets {
        hashedPassword = lib.mkForce null;
        hashedPasswordFile = config.sops.secrets."${userPasswordSecretName}".path;
      })
    ];

    root = lib.mkMerge [
      {
        hashedPassword = ensurePassword rootHashedPasswordDefault;
      }
      (lib.mkIf hasSecrets {
        hashedPassword = lib.mkForce null;
        hashedPasswordFile = config.sops.secrets."${rootPasswordSecretName}".path;
      })
    ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
}
