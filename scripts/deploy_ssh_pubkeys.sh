#!/bin/bash

CSV="csv/linux_targets.csv"
SSH_KEY="/home/jenkins/.ssh/id_rsa.pub"
SSH_USER="robot"

if [ ! -f "$SSH_KEY" ]; then
  echo "[ERROR] Public key not found at $SSH_KEY"
  exit 1
fi

tail -n +2 "$CSV" | while IFS=',' read -r ip hostname username group; do
  echo "🔐 Deploying key to $username@$ip ($hostname)..."
  
  ssh-copy-id -i "$SSH_KEY" -o StrictHostKeyChecking=no "$username@$ip" 2>/dev/null
  
  if [[ $? -eq 0 ]]; then
    echo "✅ Success: $hostname"
  else
    echo "❌ Failed: $hostname"
  fi
done


