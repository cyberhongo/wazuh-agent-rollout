#!/bin/bash
set -e

# Defaults
CSV_FILE="csv/linux_targets.csv"
KEY_PATH="$HOME/.ssh/id_rsa.pub"
SSH_USER=""
DEFAULT_PASS=""

# Parse CLI Arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --csv) CSV_FILE="$2"; shift ;;
    --ssh-key) KEY_PATH="$2"; shift ;;
    --ssh-user) SSH_USER="$2"; shift ;;
    --password) DEFAULT_PASS="$2"; shift ;;
    *) echo -e "\033[0;31m[ERROR]\033[0m Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# Validations
[[ -f "$CSV_FILE" ]] || { echo -e "\033[0;31m[ERROR]\033[0m CSV file not found: $CSV_FILE"; exit 1; }
[[ -f "$KEY_PATH" ]] || { echo -e "\033[0;31m[ERROR]\033[0m SSH public key not found: $KEY_PATH"; exit 1; }
[[ -n "$SSH_USER" ]] || { echo -e "\033[0;31m[ERROR]\033[0m SSH_USER not provided."; exit 1; }
[[ -n "$DEFAULT_PASS" ]] || { echo -e "\033[0;31m[ERROR]\033[0m DEFAULT_PASS not provided."; exit 1; }

echo "[INFO] Deploying SSH key to Linux targets using: $KEY_PATH"
bash scripts/deploy_ssh_pubkeys.sh "$CSV_FILE" "$KEY_PATH" "$SSH_USER" "$DEFAULT_PASS"

echo "[INFO] Installing Wazuh agent on Linux targets..."
bash scripts/enroll_linux_agent.sh "$CSV_FILE" "$SSH_USER" "$KEY_PATH" "$DEFAULT_PASS"

echo "[INFO] Wazuh agent installation completed successfully."
