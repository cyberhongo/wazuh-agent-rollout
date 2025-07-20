#!/usr/bin/env bash
# deploy_ssh_pubkeys.sh – Install Jenkins public key on Linux targets

set -euo pipefail

CSV_FILE="csv/linux_targets.csv"
PUBKEY_PATH="${1:-$HOME/.ssh/jenkins_id.pub}"

if [[ ! -f "$CSV_FILE" ]]; then
  echo "❌ CSV file '$CSV_FILE' not found." >&2
  exit 1
fi

if [[ ! -f "$PUBKEY_PATH" ]]; then
  echo "❌ Public key '$PUBKEY_PATH' not found." >&2
  exit 1
fi

echo -e "\n🔐 Deploying public key to Linux fleet...\n"

while IFS=',' read -r IP HOST USER GROUP EXTRA; do
  [[ -z "${IP// }" || "$IP" =~ ^# ]] && continue

  USER=${USER:-robot}
  HOSTNAME=${HOST:-$IP}

  echo -e "➡️  $HOSTNAME ($IP) as $USER"
  ssh-copy-id -i "$PUBKEY_PATH" -o StrictHostKeyChecking=no "${USER}@${IP}"

done < "$CSV_FILE"

echo -e "\n✅ Public key deployment complete."
