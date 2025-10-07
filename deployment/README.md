# Deployment helper

`deploy.sh` orchestrates an unattended install by collecting credentials,
staging the LUKS passphrase on the target, and invoking `nixos-anywhere` with
the `ascraeus` configuration. Defaults are sourced from `secrets.env` when it
exists; copy `secrets.env.example` to get started.

Generated user data lives in `deployment/generated/user.nix` (ignored by git).
Transient secrets such as the LUKS passphrase are placed under
`deployment/runtime/` and cleaned up automatically after each run.
