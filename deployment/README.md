# Deployment helper

`deploy.sh` orchestrates an unattended install by decrypting credentials from
`secrets/ascraeus.secrets.json`, staging the LUKS passphrase on the target, and
invoking `nixos-anywhere` with the `ascraeus` configuration.

The script expects `sops`, `python3`, and an age private key (either at the
default `~/.config/sops/age/keys.txt` path or provided through
`SOPS_AGE_KEY_FILE`). Secrets are decrypted into `deployment/runtime/`, which is
cleared automatically after each run.
