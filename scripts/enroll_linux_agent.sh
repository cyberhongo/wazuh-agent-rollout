#!/bin/bash

CSV_FILE="$1"

while IFS=',' read -r ip hostname username group; do
  echo "[INFO] Connecting to $hostname ($ip)..."

  ssh -o StrictHostKeyChecking=no "$username@$ip" <<EOF
    sudo systemctl stop wazuh-agent || true
    sudo WAZUH_MANAGER='enroll.cyberhongo.com' WAZUH_PORT='5443' WAZUH_GROUP='$group' agent-auth -m enroll.cyberhongo.com -p 5443 -A "$hostname"
    sudo systemctl enable --now wazuh-agent
EOF

done < <(tail -n +2 "$CSV_FILE")
