# Ascraeus desktop profile

The Ascraeus profile assembles the shared modules with hardware specific
settings for the AMD/NVIDIA workstation targeted by this project. Files are
kept small and purposeful:

* `hardware.nix` — firmware, bootloader and GPU drivers
* `storage.nix` — disko layout for /dev/sdc (boot) and /dev/sda (LUKS/LVM root)
* `networking.nix` — hostname, firewall, and SSH policy
* `desktop.nix` — KDE Plasma 6 desktop stack
* `users.nix` — immutable user definitions driven by sops-nix secrets
* `services.nix` — supporting services and packages
* `performance.nix` — tuned kernel and power-management defaults
