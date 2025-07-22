#!/bin/bash

CSV_FILE="$1"
SSH_USER="$2"
SSH_KEY="$3"

echo "[*] Beginning rollout to Linux agents from $CSV_FILE..."

# Skip the header line
tail -n +2 "$CSV_FILE" | while IFS=',' read -r HOSTNAME IP USER GROUP; do
    echo "➡ Deploying to $HOSTNAME ($IP)..."

    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$SSH_USER@$IP" bash -s <<'EOF'
echo -e "\e[34m:: [$HOSTNAME] Starting Wazuh agent enrollment ::\e[0m"

# Stop and purge any existing agent
echo "[*] Stopping & purging existing agent (if any)…"
sudo systemctl stop wazuh-agent 2>/dev/null
sudo apt-get purge -y wazuh-agent 2>/dev/null

# Download and install the agent
echo "[*] Downloading latest Wazuh agent 4.12.0…"
curl -sO https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.12.0-1_amd64.deb

echo "[*] Installing agent…"
sudo dpkg -i wazuh-agent_4.12.0-1_amd64.deb

# Configure manager address
echo "[*] Patching ossec.conf with manager address enroll.cyberhongo.com…"
sudo sed -i 's|<address>.*</address>|<address>enroll.cyberhongo.com</address>|' /var/ossec/etc/ossec.conf

# Enable and start agent
sudo systemctl daemon-reexec
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
EOF

    if [ $? -eq 0 ]; then
        echo "✅ $IP ($HOSTNAME): Enrollment completed"
    else
        echo "❌ $IP ($HOSTNAME): Enrollment failed"
    fi

done
