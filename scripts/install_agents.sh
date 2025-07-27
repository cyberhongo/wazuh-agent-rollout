#!/bin/bash

# install_agents.sh
# Purpose: Install Wazuh agent and auto-enroll via environment-based agent-auth.
# Usage: ./install_agents.sh <group_name>

set -euo pipefail

GROUP="${1:-lucid-linux}"
WAZUH_MANAGER="enroll.cyberhongo.com"
WAZUH_AGENT_VERSION="4.12.0-1"
WAZUH_AGENT_DEB="wazuh-agent_${WAZUH_AGENT_VERSION}_amd64.deb"
DOWNLOAD_URL="https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/${WAZUH_AGENT_DEB}"

echo "[DEBUG] install_agents.sh started with args: $GROUP"
echo "[INFO] Installing Wazuh agent for group: $GROUP"

# Download agent package
echo "[INFO] Downloading Wazuh agent ${WAZUH_AGENT_VERSION}..."
wget -q "$DOWNLOAD_URL" -O "$WAZUH_AGENT_DEB"

# Install with ENV to auto-trigger agent-auth via postinst script
echo "[INFO] Installing package with auto-enroll via dpkg..."
sudo WAZUH_MANAGER="$WAZUH_MANAGER" WAZUH_AGENT_GROUP="$GROUP" dpkg -i "./$WAZUH_AGENT_DEB"

# Cleanup
rm -f "./$WAZUH_AGENT_DEB"

# Enable and start agent
echo "[INFO] Enabling and starting Wazuh agent..."
sudo systemctl daemon-reexec || true
sudo systemctl enable wazuh-agent
sudo systemctl restart wazuh-agent

echo "[SUCCESS] Wazuh agent installed and enrolled successfully for group: $GROUP"
