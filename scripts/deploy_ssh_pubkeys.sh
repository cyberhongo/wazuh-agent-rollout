#!/bin/bash
set -e

CSV_FILE="$1"
SSH_PUBKEY="$2"
SSH_USER="$3"
DEFAULT_PASS="$4"

if [[ -z "$CSV_FILE" || -z "$SSH_PUBKEY" || -z "$SSH_USER" || -z "$DEFAULT_PASS" ]]; then
  echo -e "\033[0;31m[ERROR]\033[0m Missing arguments. Usage: $0 <csv_file> <ssh_pubkey> <ssh_user> <default_pass>"
  exit 1
fi

[[ -f "$CSV_FILE" ]] || { echo -e "\033[0;31m[ERROR]\033[0m CSV file not found: $CSV_FILE"; exit 1; }
[[ -f "$SSH_PUBKEY" ]] || { echo -e "\033[0;31m[ERROR]\033[0m SSH public key not found: $SSH_PUBKEY"; exit 1; }

while IFS=, read -r ip hostname user group; do
  [[ "$ip" =~ ^#.*$ || -z "$ip" ]] && continue
  echo "[INFO] Deploying SSH key to $hostname ($ip)"

  sshpass -p "$DEFAULT_PASS" ssh-copy-id -i "$SSH_PUBKEY" -o StrictHostKeyChecking=no "$SSH_USER@$ip"
  if [[ $? -eq 0 ]]; then
    echo "[SUCCESS] SSH key deployed to $hostname ($ip)"
  else
    echo -e "\033[0;31m[FAILURE]\033[0m Could not deploy SSH key to $hostname ($ip)"
  fi

done < <(tail -n +2 "$CSV_FILE")
