#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
DEFAULTS_FILE="${SCRIPT_DIR}/secrets.env"
GENERATED_DIR="${SCRIPT_DIR}/generated"
RUNTIME_DIR="${SCRIPT_DIR}/runtime"
USER_FILE="${GENERATED_DIR}/user.nix"
LUKS_FILE="${RUNTIME_DIR}/luks-passphrase"

mkdir -p "${GENERATED_DIR}" "${RUNTIME_DIR}"
chmod 700 "${GENERATED_DIR}" "${RUNTIME_DIR}"

cleanup() {
  rm -f "${LUKS_FILE}"
}
trap cleanup EXIT

if [[ -f "${DEFAULTS_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${DEFAULTS_FILE}"
fi

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

read_secret() {
  local prompt="$1"
  local default="$2"
  local value
  if [[ -n "${default}" ]]; then
    read -r -s -p "${prompt} [press enter to keep default]: " value
    echo
    if [[ -z "${value}" ]]; then
      value="${default}"
    fi
  else
    read -r -s -p "${prompt}: " value
    echo
  fi
  echo "${value}"
}

hash_password() {
  local password="$1"
  if command -v openssl >/dev/null 2>&1; then
    openssl passwd -6 "${password}"
  else
    nix shell --inputs-from "${REPO_ROOT}" nixpkgs#openssl --command openssl passwd -6 "${password}"
  fi
}

escape_nix_string() {
  local input="$1"
  printf '%s' "${input}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

target_host=$(prompt_with_default "Target host (user@host)" "${DEPLOY_TARGET_HOST:-root@192.168.1.50}")
ssh_port=$(prompt_with_default "SSH port" "${DEPLOY_SSH_PORT:-22}")
username=$(prompt_with_default "Primary username" "${DEPLOY_USERNAME:-orion}")
full_name=$(prompt_with_default "Full name" "${DEPLOY_FULL_NAME:-Primary User}")
user_password=$(read_secret "Password for ${username}" "${DEPLOY_USER_PASSWORD:-}")
root_default="${DEPLOY_ROOT_PASSWORD:-${user_password}}"
root_password=$(read_secret "Root password" "${root_default}")
encryption_passphrase=$(read_secret "LUKS encryption passphrase" "${DEPLOY_LUKS_PASSPHRASE:-}")

if [[ -z "${encryption_passphrase}" ]]; then
  echo "Encryption passphrase is required." >&2
  exit 1
fi

user_hash=$(hash_password "${user_password}")
root_hash=$(hash_password "${root_password}")

escaped_username=$(escape_nix_string "${username}")
escaped_full_name=$(escape_nix_string "${full_name}")
escaped_user_hash=$(escape_nix_string "${user_hash}")
escaped_root_hash=$(escape_nix_string "${root_hash}")

cat > "${USER_FILE}" <<USER_CFG
{
  username = "${escaped_username}";
  fullName = "${escaped_full_name}";
  hashedPassword = "${escaped_user_hash}";
  rootHashedPassword = "${escaped_root_hash}";
}
USER_CFG
chmod 600 "${USER_FILE}"

echo "${encryption_passphrase}" > "${LUKS_FILE}"
chmod 600 "${LUKS_FILE}"

scp -P "${ssh_port}" "${LUKS_FILE}" "${target_host}:/tmp/luks-passphrase"
ssh -p "${ssh_port}" "${target_host}" 'chmod 600 /tmp/luks-passphrase'

install_cmd=(
  nixos-anywhere
  --flake "${REPO_ROOT}#ascraeus"
  --ssh-port "${ssh_port}"
  "${target_host}"
)

echo "Starting deployment with nixos-anywhere..."
"${install_cmd[@]}"

ssh -p "${ssh_port}" "${target_host}" 'rm -f /tmp/luks-passphrase' || true

echo "Deployment completed."
