#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
SOPS_FILE="${REPO_ROOT}/secrets/ascraeus.secrets.json"
RUNTIME_DIR="${SCRIPT_DIR}/runtime"
LUKS_FILE="${RUNTIME_DIR}/luks-passphrase"
SECRET_JSON="${RUNTIME_DIR}/secrets.json"
AGE_KEY_SOURCE="${SOPS_AGE_KEY_FILE:-${HOME}/.config/sops/age/keys.txt}"
AGE_KEY_DEST="/var/lib/sops-nix/age.key"
EXTRA_FILES_DIR="${SCRIPT_DIR}/runtime/extra-files"

mkdir -p "${RUNTIME_DIR}"
chmod 700 "${RUNTIME_DIR}"
rm -rf "${EXTRA_FILES_DIR}"

cleanup() {
  rm -f "${LUKS_FILE}" "${SECRET_JSON}"
  rm -rf "${EXTRA_FILES_DIR}"
}
trap cleanup EXIT

require_tool() {
  local tool="$1"
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "${tool} is required but was not found in PATH." >&2
    echo "Enter the development shell with 'nix develop' to access all dependencies." >&2
    exit 1
  fi
}

require_tool sops
require_tool python3

if [[ ! -f "${SOPS_FILE}" ]]; then
  cat >&2 <<MESSAGE
Secrets file not found at ${SOPS_FILE}.
Create it with sops (see secrets/README.md) before running this script.
MESSAGE
  exit 1
fi

if [[ ! -f "${AGE_KEY_SOURCE}" ]]; then
  cat >&2 <<MESSAGE
AGE key file not found at ${AGE_KEY_SOURCE}.
Set SOPS_AGE_KEY_FILE to the location of your private key or place it at the default path.
MESSAGE
  exit 1
fi

sops --decrypt "${SOPS_FILE}" > "${SECRET_JSON}"
chmod 600 "${SECRET_JSON}"

extract_json() {
  local path="$1"
  python3 - "$SECRET_JSON" "$path" <<'PY'
import json
import sys


def get_value(data, parts):
    value = data
    for part in parts:
        if part not in value:
            raise KeyError(part)
        value = value[part]
    return value


with open(sys.argv[1], 'r', encoding='utf-8') as handle:
    data = json.load(handle)

keys = sys.argv[2].split('.') if sys.argv[2] else []
try:
    result = get_value(data, keys) if keys else data
except KeyError as err:
    raise SystemExit(f"missing key: {err.args[0]}") from err

if isinstance(result, (dict, list)):
    json.dump(result, sys.stdout)
else:
    sys.stdout.write(str(result))
PY
}

encryption_passphrase=$(extract_json "install.luksPassphrase")
if [[ -z "${encryption_passphrase}" ]]; then
  echo "LUKS passphrase is missing from ${SOPS_FILE}." >&2
  exit 1
fi

printf '%s' "${encryption_passphrase}" > "${LUKS_FILE}"
chmod 600 "${LUKS_FILE}"

mkdir -p "${EXTRA_FILES_DIR}/var/lib/sops-nix"
cp "${AGE_KEY_SOURCE}" "${EXTRA_FILES_DIR}${AGE_KEY_DEST}"
chmod 600 "${EXTRA_FILES_DIR}${AGE_KEY_DEST}"

prompt_with_default() {
  local prompt="$1"
  local default="$2"
  local value
  if [[ -n "${default}" ]]; then
    read -r -p "${prompt} [${default}]: " value
    if [[ -z "${value}" ]]; then
      value="${default}"
    fi
  else
    read -r -p "${prompt}: " value
  fi
  echo "${value}"
}

install_cmd=(
  nix run github:nix-community/nixos-anywhere
  --
  --flake "${REPO_ROOT}#ascraeus"
)

target_host=$(prompt_with_default "Target host (user@host)" "${DEPLOY_TARGET_HOST:-root@192.168.1.50}")
ssh_port=$(prompt_with_default "SSH port" "${DEPLOY_SSH_PORT:-22}")

install_cmd+=(
  --ssh-port "${ssh_port}"
  --build-on auto
  --disk-encryption-keys /tmp/luks-passphrase "${LUKS_FILE}"
  --extra-files "${EXTRA_FILES_DIR}"
  --chown /var/lib/sops-nix 0:0
  --chown /var/lib/sops-nix/age.key 0:0
  "${target_host}"
)

cat <<'INFO'
Starting deployment with nixos-anywhere...
INFO
"${install_cmd[@]}"

echo "Deployment completed."
