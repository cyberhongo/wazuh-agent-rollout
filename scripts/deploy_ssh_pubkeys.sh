#!/bin/bash

PUBKEY="/home/robot/.ssh/id_rsa.pub"
CSV="csv/linux_targets.csv"

if [ ! -f "$PUBKEY" ]; then
  echo "[ERROR] Public key not found at $PUBKEY"
  exit 1
fi

if [ ! -f "$CSV" ]; then
  echo "[ERROR] CSV file not found at $CSV"
  exit 1
fi

tail -n +2 "$CSV" | while IFS=',' read -r ip hostname username group; do
  echo "🔐 Injecting key into $username@$ip ($hostname)..."
  ssh-copy-id -i "$PUBKEY" "$username@$ip"
done
