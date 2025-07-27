#!/bin/bash

set -euo pipefail

CSV_FILE="$1"
SSH_KEY="$2"
LOG_DIR="logs"

mkdir -p "$LOG_DIR"

if [[ ! -f "$CSV_FILE" ]]; then
  echo "❌ CSV file not found: $CSV_FILE"
  exit 1
fi

echo "[*] Beginning rollout to Linux agents from $CSV_FILE..."

while IFS=, read -r ip hostname username group; do
  [[ "$ip" == "ip" ]] && continue

  echo "➡ Deploying to $hostname ($ip)..."

  scp -i "$SSH_KEY" -o StrictHostKeyChecking=no scripts/install_agents.sh "$username@$ip:/tmp/" > "$LOG_DIR/$hostname.log" 2>&1 || {
    echo "❌ $ip ($hostname): SCP failed" | tee -a "$LOG_DIR/$hostname.log"
    continue
  }

  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$username@$ip" \
    "chmod +x /tmp/install_agents.sh && sudo /tmp/install_agents.sh $group" >> "$LOG_DIR/$hostname.log" 2>&1

  if [[ $? -eq 0 ]]; then
    echo "✅ $ip ($hostname): Enrollment successful"
  else
    echo "❌ $ip ($hostname): Enrollment failed" | tee -a "$LOG_DIR/$hostname.log"
  fi

done < "$CSV_FILE"

echo "[*] Linux rollout complete. Logs stored in $LOG_DIR/"
exit 0
