#!/bin/bash

# Purpose: Install Wazuh Agent 4.12.0-1 and enroll with correct manager and group
# Version: v1.2
# Author: Lucidity Consulting | robot@cyberhongo

set -euo pipefail

AGENT_VERSION="4.12.0-1"
AGENT_DEB_URL="https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_${AGENT_VERSION}_amd64.deb"
AGENT_DEB_FILE="wazuh-agent_${AGENT_VERSION}_amd64.deb"

MANAGER="enroll.cyberhongo.com"
PORT=5443
GROUP="${WAZUH_AGENT_GROUP:-lucid-linux}"

log() {
  echo -e "[INFO] $1"
}

err() {
  echo -e "[ERROR] $1" >&2
  exit 1
}

install_agent() {
  log "Updating APT cache..."
  sudo apt-get update -qq

  log "Downloading Wazuh agent ${AGENT_VERSION}..."
  wget -q "$AGENT_DEB_URL" -O "$AGENT_DEB_FILE"

  log "Installing agent..."
  sudo dpkg -i "./$AGENT_DEB_FILE" || sudo apt-get install -f -y

  log "Setting manager IP to $MANAGER:$PORT and group to $GROUP..."
  sudo WAZUH_MANAGER="$MANAGER" \
       WAZUH_MANAGER_PORT="$PORT" \
       WAZUH_AGENT_GROUP="$GROUP" \
       /var/ossec/bin/agent-auth -m "$MANAGER" -p "$PORT" -g "$GROUP"

  log "Enabling and starting Wazuh agent..."
  sudo systemctl daemon-reexec
  sudo systemctl enable wazuh-agent
  sudo systemctl start wazuh-agent

  log "✅ Agent installed and enrolled successfully."
}

# Run
install_agent
