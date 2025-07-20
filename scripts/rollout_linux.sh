#!/bin/bash

CSV="$1"
USER="$2"
KEY="$3"

if [[ ! -f "$CSV" ]]; then
  echo "❌ Linux CSV not found: $CSV"
  exit 1
fi

if [[ -z "$USER" || -z "$KEY" ]]; then
  echo "❌ SSH credentials missing"
  exit 1
fi

echo "[*] Beginning rollout to Linux agents from $CSV..."
while IFS=',' read -r ip hostname username group; do
  [[ "$ip" == "ip" ]] && continue  # skip header
  echo "➡ Deploying to $hostname ($ip)..."

  ssh -i "$KEY" -o StrictHostKeyChecking=no "$USER@$ip" "bash -s" < ./scripts/enroll_linux_agent.sh
  if [[ $? -eq 0 ]]; then
    echo "✅ $hostname ($ip): Enrollment succeeded"
  else
    echo "❌ $hostname ($ip): Enrollment failed"
  fi
done < "$CSV"
