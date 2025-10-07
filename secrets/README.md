# Secrets management

Secrets are handled with [sops](https://github.com/mozilla/sops) and consumed at
runtime via [sops-nix](https://github.com/Mic92/sops-nix). The NixOS
configuration expects an encrypted JSON document at
`secrets/ascraeus.secrets.json` with the following structure:

```json
{
  "users": {
    "orion": {
      "hashedPassword": "<sha512crypt hash>"
    },
    "root": {
      "hashedPassword": "<sha512crypt hash>"
    }
  },
  "install": {
    "luksPassphrase": "<passphrase used by disko>"
  }
}
```

Use the provided `ascraeus.secrets.example.json` as a starting point. Encrypt it
with `sops` and commit the encrypted output if desired:

```bash
cp secrets/ascraeus.secrets.example.json secrets/ascraeus.secrets.json
sops secrets/ascraeus.secrets.json
```

Place your age private key at `~/.config/sops/age/keys.txt` or export the
`SOPS_AGE_KEY_FILE` environment variable so both `sops` and the deployment
script can locate it.
