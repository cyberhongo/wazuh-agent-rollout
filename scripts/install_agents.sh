#!/bin/bash
set -euo pipefail

CSV_FILE="csv/linux_targets.csv"
KEY_PATH="/root/.ssh/jenkins_id"
ENROLL_SCRIPT="./scripts/enroll_linux_agent.sh"

# Load env vars
source .env

# Validate required variables
: "${ENROLL_FQDN:?ENROLL_FQDN is not set in .env}"
: "${ENROLL_PORT:?ENROLL_PORT is not set in .env}"
: "${ENROLL_SECRET:?ENROLL_SECRET is not set in .env}"

echo "[*] Starting Wazuh agent installation for Linux hosts..."

while IFS=',' read -r HOST IP USER GROUP; do
    [[ "$HOST" =~ ^#|^$ ]] && continue

    echo "[*] Processing $HOST ($IP) as user $USER in group $GROUP"

    ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" "$USER@$IP" bash -s <<EOF
        curl -sO https://packages.wazuh.com/4.12/wazuh-agent-4.12.0.deb
        sudo dpkg -i wazuh-agent-4.12.0.deb || sudo apt-get install -f -y
        sudo systemctl enable wazuh-agent
EOF

    echo "[*] Enrolling $HOST into group $GROUP via $ENROLL_FQDN:$ENROLL_PORT"
    bash "$ENROLL_SCRIPT" "$IP" "$USER" "$GROUP" "$KEY_PATH"

    echo "[*] $HOST enrolled successfully."
done < "$CSV_FILE"

echo "[✔] All Linux agents installed and enrolled."
