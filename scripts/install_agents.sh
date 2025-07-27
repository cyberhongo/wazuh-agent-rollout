#!/bin/bash
set -e

# Default values
CSV_PATH=""
SSH_KEY=""
SSH_USER="jenkins"

# Parse arguments first
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --csv) CSV_PATH="$2"; shift ;;
    --ssh-key) SSH_KEY="$2"; shift ;;
    --ssh-user) SSH_USER="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

# Validate
if [[ -z "$CSV_PATH" || -z "$SSH_KEY" || -z "$SSH_USER" ]]; then
  echo "[ERROR] Missing required parameters."
  echo "Usage: $0 --csv <path> --ssh-key <private_key> --ssh-user <user>"
  exit 1
fi

PUB_KEY="${SSH_KEY}.pub"

# Generate public key if not exists
if [[ ! -f "$PUB_KEY" ]]; then
  echo "[WARN] SSH public key not found at $PUB_KEY — generating..."
  ssh-keygen -y -f "$SSH_KEY" > "$PUB_KEY"
  echo "[INFO] Generated public key: $PUB_KEY"
fi

echo "[INFO] Using target CSV: $CSV_PATH"
echo "[INFO] Using SSH user: $SSH_USER"
echo "[INFO] Using SSH key: $SSH_KEY"

# Deploy SSH key to targets
echo "[INFO] Deploying SSH key to all targets..."
scripts/deploy_ssh_pubkeys.sh "$PUB_KEY" ""

# Run installer
echo "[INFO] Installing Wazuh agent on all targets..."
scripts/rollout_linux.sh --csv "$CSV_PATH" --ssh-user "$SSH_USER" --ssh-key "$SSH_KEY"
