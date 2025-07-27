#!/bin/bash
set -euo pipefail

# Defaults
CSV_FILE="csv/linux_targets.csv"
SSH_USER="robot"
SSH_KEY="$HOME/.ssh/id_rsa"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --csv)
      CSV_FILE="$2"
      shift 2
      ;;
    --ssh-user)
      SSH_USER="$2"
      shift 2
      ;;
    --ssh-key)
      SSH_KEY="$2"
      shift 2
      ;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# Validate inputs
if [[ ! -f "$CSV_FILE" ]]; then
  echo "[ERROR] CSV file not found: $CSV_FILE"
  exit 1
fi

if [[ ! -f "$SSH_KEY" ]]; then
  echo "[ERROR] SSH private key not found: $SSH_KEY"
  exit 1
fi

echo "[INFO] Using target CSV: $CSV_FILE"
echo "[INFO] Using SSH user: $SSH_USER"
echo "[INFO] Using SSH key: $SSH_KEY"

# Ensure scripts exist
DEPLOY_KEY_SCRIPT="scripts/deploy_ssh_pubkeys.sh"
AGENT_ENROLL_SCRIPT="scripts/enroll_linux_agent.sh"

for script in "$DEPLOY_KEY_SCRIPT" "$AGENT_ENROLL_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "[ERROR] Required script missing or not executable: $script"
    exit 1
  fi
done

# Deploy SSH keys to targets
echo "[INFO] Deploying SSH key to all targets..."
bash "$DEPLOY_KEY_SCRIPT" --csv "$CSV_FILE" --ssh-key "$SSH_KEY" --ssh-user "$SSH_USER"

# Enroll Wazuh agents
echo "[INFO] Installing and enrolling Wazuh agents..."
bash "$AGENT_ENROLL_SCRIPT" --csv "$CSV_FILE" --ssh-key "$SSH_KEY" --ssh-user "$SSH_USER"

echo "[SUCCESS] All Linux agents processed successfully."
