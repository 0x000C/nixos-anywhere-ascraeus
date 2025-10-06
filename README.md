# nixos-anywhere-ascraeus

This repository contains a complete NixOS configuration and deployment tooling
for provisioning the **Ascraeus** desktop using
[`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere).

## Target hardware layout

* UEFI `/boot` partition on **/dev/sdc** (16&nbsp;GiB USB flash media)
* Encrypted root volume on **/dev/sda** (1&nbsp;TiB SATA SSD) using LUKS on LVM with an ext4 filesystem
* AMD CPU microcode updates and NVIDIA proprietary drivers
* KDE Plasma 6 desktop environment with SDDM login manager

Disk provisioning is handled through the `disko` module. `/dev/sdc` is prepared
as a GPT disk with a single EFI system partition formatted as FAT32. `/dev/sda`
becomes a single GPT partition encrypted with LUKS, providing the `vg0` volume
group. Two logical volumes are created: `root` (ext4, mounted at `/`) and `swap`
(16&nbsp;GiB).

## Repository layout

```
.
├── deployment            # Deployment tooling and defaults
│   ├── deploy.sh         # Interactive deployment helper
│   ├── defaults          # Default data used by the configuration
│   └── secrets.env.example
├── hosts                 # Host specific configuration split into small modules
│   ├── ascraeus          # Ascraeus desktop configuration
│   └── common            # Reusable building blocks
└── flake.nix             # Entry point for nixos-anywhere
```

Every configuration area is split into a focused module to keep files small and
readable. Host specific overrides live under `hosts/ascraeus/` while shared
settings live under `hosts/common/`.

## Prerequisites

* A NixOS machine acting as the deployment controller (run all commands as
  `root`)
* Network access to the target NixOS live ISO (`root@<ip>`)
* `git` and `nixos-anywhere` available locally (included in the dev shell)

To enter a development shell with the required tooling, run:

```bash
nix develop
```

## Preparing secrets

Copy the example secrets file and edit the defaults to suit your environment.
This file is never committed to git.

```bash
cp deployment/secrets.env.example deployment/secrets.env
$EDITOR deployment/secrets.env
```

## Running a deployment

1. Boot the target machine with the NixOS live ISO and ensure SSH access as the
   `root` user.
2. Connect the USB drive that will host `/boot` as `/dev/sdc`.
3. From the controller machine, execute:

   ```bash
   ./deployment/deploy.sh
   ```

4. Answer the prompts for the target host, user credentials, and encryption
   passphrase. Defaults are loaded from `deployment/secrets.env` when present.
5. The script will generate the required user data, securely stage the LUKS
   passphrase on the live system, and then run `nixos-anywhere` with the
   `ascraeus` configuration.

Upon completion the system reboots into the freshly installed NixOS desktop.
Change the default passwords immediately after first boot if you used the
example values.

## Updating configuration

Modify the relevant module under `hosts/ascraeus/` or extend the shared modules
under `hosts/common/`. Keep changes small and targeted to preserve readability.

After making changes you can redeploy using the same `deployment/deploy.sh`
script. The generated secrets are refreshed on each run.
