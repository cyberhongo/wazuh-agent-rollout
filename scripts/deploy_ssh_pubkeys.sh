#!/bin/bash

set -e

# Default vars
CSV="csv/linux_targets.csv"
SSH_KEY="/home/jenkins/.ssh/id_rsa.pub"
SSH_USER="robot"
PASSWORD=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
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
    --password)
      PASSWORD="$2"
      shift 2
      ;;
    *)
      echo "[ERROR] Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [[ ! -f "$SSH_KEY" ]]; then
  echo "[ERROR] Public key not found at $SSH_KEY"
  exit 1
fi

if [[ ! -f "$CSV" ]]; then
  echo "[ERROR] CSV not found: $CSV"
  exit 1
fi

if [[ -z "$PASSWORD" ]]; then
  echo "[ERROR] SSH password not provided. Use --password option."
  exit 1
fi

echo "[*] Distributing SSH key using $SSH_KEY and $CSV..."

tail -n +2 "$CSV" | while IFS=',' read -r ip hostname username group; do
  echo "🔐 Deploying key to $username@$ip ($hostname)..."

  sshpass -p "$PASSWORD" ssh-copy-id -i "$SSH_KEY" -o StrictHostKeyChecking=no "$username@$ip" &>/dev/null

  if [[ $? -eq 0 ]]; then
    echo "✅ Success: $hostname"
  else
    echo "❌ Failed: $hostname"
  fi

done
