#!/bin/bash

set -euo pipefail

CSV=""
SSH_USER=""
SSH_KEY=""
DEFAULT_PASS="changeme"

# Usage
usage() {
  echo "Usage: $0 --csv <csv_file> --ssh-key <private_key_path> --ssh-user <username>"
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --csv)
      CSV="$2"
      shift 2
      ;;
    --ssh-key)
      SSH_KEY="$2"
      shift 2
      ;;
    --ssh-user)
      SSH_USER="$2"
      shift 2
      ;;
    *)
      echo "[ERROR] Unknown option: $1"
      usage
      ;;
  esac
done

# Validate
[[ -z "$CSV" || -z "$SSH_USER" || -z "$SSH_KEY" ]] && usage

echo "[INFO] Using target CSV: $CSV"
echo "[INFO] Using SSH user: $SSH_USER"
echo "[INFO] Using SSH key: $SSH_KEY"

# Convert private key to public key path
PUB_KEY="${SSH_KEY}.pub"

# Validate pubkey
if [[ ! -f "$PUB_KEY" ]]; then
  echo "[ERROR] SSH public key not found at $PUB_KEY"
  exit 1
fi

# Step 1: Deploy SSH keys
echo "[INFO] Deploying SSH key to all targets..."
scripts/deploy_ssh_pubkeys.sh "$PUB_KEY" "$DEFAULT_PASS"

# Step 2: Run rollout
echo "[INFO] Running Linux agent rollout..."
scripts/rollout_linux.sh "$CSV" "$SSH_USER" "$SSH_KEY"

echo "[INFO] Linux Wazuh agent rollout complete."
