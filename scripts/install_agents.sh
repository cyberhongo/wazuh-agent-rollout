#!/bin/bash

set -euo pipefail

# Default values
CSV=""
SSH_KEY=""
SSH_USER=""
PASSWORD=""

# Argument parsing
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --csv) CSV="$2"; shift ;;
        --ssh-key) SSH_KEY="$2"; shift ;;
        --ssh-user) SSH_USER="$2"; shift ;;
        --password) PASSWORD="$2"; shift ;;
        *) echo "[ERROR] Unknown argument: $1" >&2; exit 1 ;;
    esac
    shift
done

if [[ -z "$CSV" || -z "$SSH_KEY" || -z "$SSH_USER" || -z "$PASSWORD" ]]; then
    echo "[ERROR] Missing required arguments." >&2
    echo "Usage: $0 --csv <file> --ssh-key <path> --ssh-user <name> --password <pass>" >&2
    exit 1
fi

echo "[INFO] Installing Wazuh agents from: $CSV"
echo "[INFO] Using SSH key: $SSH_KEY"

tail -n +2 "$CSV" | while IFS=',' read -r ip hostname username group; do
    echo "🚀 Installing agent on $hostname ($ip) as $username..."

    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$username@$ip" bash -s <<EOF
sudo apt-get update
sudo apt-get install -y curl gnupg2

curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list

sudo apt-get update
sudo apt-get install -y wazuh-agent=4.12.0-1

sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
EOF

    echo "🔑 Requesting enrollment..."
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$username@$ip" sudo /var/ossec/bin/agent-auth -m enroll.cyberhongo.com -p 5443

    echo "✅ Installed and enrolled: $hostname ($ip)"
done
