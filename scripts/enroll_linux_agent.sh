#!/bin/bash

set -euo pipefail

# Function to run commands as root if not already
run() {
  if [[ $EUID -eq 0 ]]; then "$@"; else sudo "$@"; fi
}

AGENT_NAME="$(hostname -s)"
WAZUH_MANAGER="enroll.cyberhongo.com"
WAZUH_GROUP="lucid-linux"
WAZUH_AGENT_VERSION="4.12.0"
WAZUH_DEB="wazuh-agent_${WAZUH_AGENT_VERSION}-1_amd64.deb"
TMP_DIR="/tmp"

echo -e "\033[34m:: [${AGENT_NAME}] Starting Wazuh agent enrollment ::\033[0m"

echo "[*] Stopping & purging existing agent (if any)…"
run systemctl stop wazuh-agent || true
run apt-get -y purge wazuh-agent || true

echo "[*] Downloading latest Wazuh agent ${WAZUH_AGENT_VERSION}…"
curl -s -L -o "${TMP_DIR}/${WAZUH_DEB}" \
  "https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/${WAZUH_DEB}"

echo "[*] Installing agent…"
run dpkg -i "${TMP_DIR}/${WAZUH_DEB}"

echo "[*] Patching ossec.conf with manager address ${WAZUH_MANAGER}…"
CONF="/var/ossec/etc/ossec.conf"
run sed -i "s|<address>.*</address>|<address>${WAZUH_MANAGER}</address>|" "$CONF"

echo "[*] Registering with Wazuh manager as '${AGENT_NAME}' in group '${WAZUH_GROUP}'…"
run /var/ossec/bin/agent-auth -m "$WAZUH_MANAGER" -A "$AGENT_NAME" -G "$WAZUH_GROUP"

echo "[*] Enabling and starting wazuh-agent service…"
run systemctl daemon-reexec
run systemctl enable wazuh-agent
run systemctl start wazuh-agent

echo -e "\033[32m✔ [${AGENT_NAME}] Enrollment complete.\033[0m"
