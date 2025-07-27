#!/bin/bash

set -e

# Defaults
CSV_FILE=""
AUTH_PASS=""
PUBKEY_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --csv)
      CSV_FILE="$2"
      shift 2
      ;;
    --authpass)
      AUTH_PASS="$2"
      shift 2
      ;;
    --pubkey)
      PUBKEY_PATH="$2"
      shift 2
      ;;
    *)
      echo "[ERROR] Unknown parameter passed: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$CSV_FILE" || -z "$AUTH_PASS" || -z "$PUBKEY_PATH" ]]; then
  echo "[ERROR] Missing required parameters."
  echo "Usage: $0 --csv <csv_file> --authpass <password> --pubkey <pubkey_path>"
  exit 1
fi

echo "[INFO] Parsing targets from $CSV_FILE..."
while IFS=, read -r ip hostname user group; do
  [[ "$ip" == "ip" ]] && continue  # Skip header

  echo "[INFO] Installing Wazuh agent on $hostname ($ip)..."

  ssh -o StrictHostKeyChecking=no -i "$PUBKEY_PATH" "$user@$ip" <<EOF
    curl -s https://packages.wazuh.com/4.x/install.sh | bash
    sudo /var/ossec/bin/agent-auth --host enroll.cyberhongo.com --port 5443 --authpass "$AUTH_PASS"
    sudo systemctl enable wazuh-agent
    sudo systemctl restart wazuh-agent
EOF

done < "$CSV_FILE"
