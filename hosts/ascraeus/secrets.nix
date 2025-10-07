{ ... }:
let
  ageKeyPath = "/var/lib/sops-nix/age.key";
in {
  sops.age.keyFile = ageKeyPath;

  systemd.tmpfiles.rules = [
    "d /var/lib/sops-nix 0750 root root -"
    "z /var/lib/sops-nix 0750 root root -"
    "Z /var/lib/sops-nix/age.key 0600 root root -"
  ];
}
