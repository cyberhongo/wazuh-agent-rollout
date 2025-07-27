#!/bin/bash
set -euo pipefail

CSV_FILE="$1"
SSH_USER="$2"
KEY_PATH="$3"
DEFAULT_PASS="$4"

[[ -f "$CSV_FILE" ]] || { echo -e "[ERROR] CSV file not found: $CSV_FILE"; exit 1; }

while IFS=',' read -r ip hostname user group; do
  echo "[INFO] Installing Wazuh agent on $hostname ($ip) in group '$group'"

  ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no "$SSH_USER@$ip" bash -s <<EOF
    set -e
    wget -q https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.12.0-1_amd64.deb
    sudo WAZUH_MANAGER='enroll.cyberhongo.com' \
         WAZUH_REGISTRATION_PASSWORD="\$DEFAULT_PASS" \
         WAZUH_AGENT_GROUP='$group' \
         dpkg -i ./wazuh-agent_4.12.0-1_amd64.deb || sudo apt-get install -f -y
    sudo systemctl enable wazuh-agent && sudo systemctl start wazuh-agent
EOF

done < <(tail -n +2 "$CSV_FILE")

echo "[INFO] All Linux agents enrolled and started successfully."
