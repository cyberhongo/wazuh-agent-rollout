#!/bin/bash

set -euo pipefail

# Input Parameters
MANAGER_FQDN="enroll.cyberhongo.com"
AGENT_GROUP="lucid-linux"
AGENT_VERSION="4.12.0-1"
DEB_FILE="wazuh-agent_${AGENT_VERSION}_amd64.deb"
AGENT_DEB_URL="https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/${DEB_FILE}"

# Download Agent
echo "[INFO] Downloading Wazuh agent ${AGENT_VERSION}..."
wget -q --show-progress "${AGENT_DEB_URL}" -O "/tmp/${DEB_FILE}"

# Install Prerequisites
echo "[INFO] Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y libcap2 libcurl4 libsystemd0

# Install Agent
echo "[INFO] Installing Wazuh agent..."
sudo WAZUH_MANAGER="${MANAGER_FQDN}" \
     WAZUH_AGENT_GROUP="${AGENT_GROUP}" \
     dpkg -i "/tmp/${DEB_FILE}" || {
        echo "[ERROR] dpkg failed. Attempting to fix with apt."
        sudo apt-get install -f -y
        sudo dpkg -i "/tmp/${DEB_FILE}"
     }

# Enable and Start
echo "[INFO] Enabling and starting wazuh-agent..."
sudo systemctl daemon-reexec
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

# Status Check
sleep 3
echo "[INFO] Agent status:"
sudo systemctl status wazuh-agent --no-pager

# Cleanup
rm -f "/tmp/${DEB_FILE}"
