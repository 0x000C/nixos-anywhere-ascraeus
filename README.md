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
│   ├── deploy.sh         # Deployment helper that unwraps SOPS secrets
│   └── defaults          # Sample data for local testing
├── secrets               # Encrypted configuration data managed by sops-nix
│   └── ascraeus.secrets.example.json
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

## Faster builds with Cachix

The flake and system configuration trust the public
[`nix-community`](https://nix-community.cachix.org) Cachix binary cache. This
allows both local builds and remote deployments to reuse pre-built derivations,
significantly cutting down the time spent compiling packages. The development
shell also ships with the `cachix` CLI should you need to inspect or warm the
cache manually.

To enter a development shell with the required tooling, run:

```bash
nix develop
```

## Preparing secrets

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix). Create
an [age](https://age-encryption.org) key pair if you do not already have one:

```bash
age-keygen -o ~/.config/sops/age/keys.txt
```

Use `sops` to create `secrets/ascraeus.secrets.json` based on the example
structure:

```bash
cp secrets/ascraeus.secrets.example.json secrets/ascraeus.secrets.json
sops secrets/ascraeus.secrets.json
```

Provide hashed passwords for both the primary user and `root` (for example with
`mkpasswd -m sha-512`). The file also stores the LUKS passphrase used by the
installer. Because the file is encrypted it can safely be committed to git.

## Running a deployment

1. Boot the target machine with the NixOS live ISO and ensure SSH access as the
   `root` user.
2. Connect the USB drive that will host `/boot` as `/dev/sdc`.
3. From the controller machine, execute:

   ```bash
   ./deployment/deploy.sh
   ```

4. Ensure your age private key is available at
   `~/.config/sops/age/keys.txt` (or export `SOPS_AGE_KEY_FILE`).
5. The script decrypts the required data with `sops`, stages the LUKS
   passphrase, copies the age key for the installed system, and then runs
   `nixos-anywhere` with the `ascraeus` configuration.

Upon completion the system reboots into the freshly installed NixOS desktop.
Change the default passwords immediately after first boot if you used the
example values.

## Updating configuration

Modify the relevant module under `hosts/ascraeus/` or extend the shared modules
under `hosts/common/`. Keep changes small and targeted to preserve readability.

After making changes you can redeploy using the same `deployment/deploy.sh`
script. Secrets remain in `secrets/ascraeus.secrets.json`, so remember to
re-encrypt the file with any new credentials before redeploying.
