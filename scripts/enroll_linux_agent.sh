#!/usr/bin/env bash
set -euo pipefail
MANAGER_FQDN="enroll.cyberhongo.com"
MANAGER_PORT="1514"
AUTH_PORT="1515"

usage() { echo "Usage: $0 -g <group>" ; exit 1 ; }
while getopts "g:" o; do case "${o}" in g) GROUP="${OPTARG}";; *) usage;; esac; done
[ -z "${GROUP:-}" ] && usage

echo "[*] Checking for existing wazuh-agent…"
if systemctl is-active --quiet wazuh-agent; then
    echo "    → stopping service"
    sudo systemctl stop wazuh-agent
fi
if dpkg -l wazuh-agent &>/dev/null; then
    echo "    → removing package & leftovers"
    sudo apt-get -y purge wazuh-agent
    sudo rm -rf /var/ossec
fi

echo "[*] Installing fresh agent 4.12.0…"
wget -q https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.12.0-1_amd64.deb -O /tmp/wazuh-agent.deb
sudo DEBIAN_FRONTEND=noninteractive \
     WAZUH_MANAGER="$MANAGER_FQDN" \
     WAZUH_MANAGER_PORT="$MANAGER_PORT" \
     WAZUH_AGENT_GROUP="$GROUP" \
     dpkg -i /tmp/wazuh-agent.deb

echo "[*] Registering via agent-auth…"
sudo /var/ossec/bin/agent-auth -m "$MANAGER_FQDN" -p "$AUTH_PORT" -g "$GROUP"

echo "[*] Starting & enabling service…"
sudo systemctl enable --now wazuh-agent
echo "[✓] $HOSTNAME enrolled."
