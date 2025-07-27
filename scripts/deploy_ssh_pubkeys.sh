#!/bin/bash

# ---------------------------------------------
# SSH Key Deployment Script
# LucidSecOps Project
# ---------------------------------------------

PUBKEY_PATH="${1:-$PUBKEY_PATH}"
DEFAULT_PASS="${2:-$DEFAULT_PASS}"
CSV_FILE="csv/linux_targets.csv"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Validate input
if [[ -z "$PUBKEY_PATH" || ! -f "$PUBKEY_PATH" ]]; then
    echo -e "${RED}[ERROR]${NC} SSH public key not found at ${PUBKEY_PATH:-'(unspecified)'}"
    echo "Usage: $0 /path/to/id_rsa.pub <default_password>"
    exit 1
fi

if [[ -z "$DEFAULT_PASS" ]]; then
    echo -e "${RED}[ERROR]${NC} DEFAULT_PASS not set or passed as argument."
    echo "Export DEFAULT_PASS or pass it as second argument."
    exit 1
fi

echo -e "${BLUE}[INFO]${NC} Using SSH public key: $PUBKEY_PATH"
echo -e "${BLUE}[INFO]${NC} Deploying using default password.\n"

while IFS=',' read -r ip hostname username group; do
    # Skip blank or header lines
    [[ "$ip" == "ip" || -z "$ip" ]] && continue

    echo -e "[*] Deploying SSH key to ${hostname} (${ip}) as ${username}..."

    sshpass -p "$DEFAULT_PASS" ssh-copy-id -i "$PUBKEY_PATH" -o StrictHostKeyChecking=no "${username}@${ip}" >/dev/null 2>&1

    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}[OK]${NC} Key copied successfully to ${ip}\n"
    else
        echo -e "${RED}[FAIL]${NC} Could not copy key to ${ip}\n"
    fi
done < "$CSV_FILE"
