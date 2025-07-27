#!/bin/bash
set -e

# Defaults
CSV_FILE="csv/linux_targets.csv"
KEY_PATH="$HOME/.ssh/id_rsa.pub"

# Parse args
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --csv) CSV_FILE="$2"; shift ;;
    --pubkey) KEY_PATH="$2"; shift ;;
    *) echo "[ERROR] Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

AGENT_INSTALL_SCRIPT="scripts/enroll_linux_agent.sh"
DEPLOY_KEY_SCRIPT="scripts/deploy_ssh_pubkeys.sh"

if [[ ! -f "$CSV_FILE" ]]; then
  echo "[ERROR] Target CSV file not found: $CSV_FILE"
  exit 1
fi

if [[ ! -f "$KEY_PATH" ]]; then
  echo "[ERROR] SSH public key not found: $KEY_PATH"
  exit 1
fi

echo "[INFO] Deploying SSH key to Linux targets..."
bash "$DEPLOY_KEY_SCRIPT" "$CSV_FILE" "$KEY_PATH"

echo "[INFO] Installing Wazuh agent on Linux targets..."
bash "$AGENT_INSTALL_SCRIPT" "$CSV_FILE"

echo "[INFO] Wazuh agent installation completed."
