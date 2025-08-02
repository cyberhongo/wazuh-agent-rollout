#!/bin/bash

set -euo pipefail

# ==== CONFIG ====
LOG_FILE="/var/log/wazuh-enroll.log"
AGENT_NAME="$(hostname -s)"
WAZUH_MANAGER="enroll.cyberhongo.com"
WAZUH_GROUP="lucid-linux"
WAZUH_AGENT_VERSION="4.12.0"
WAZUH_DEB="wazuh-agent_${WAZUH_AGENT_VERSION}-1_amd64.deb"
TMP_DIR="/tmp"
CONF_FILE="/var/ossec/etc/ossec.conf"

# ==== Ensure log file is writable ====
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ This script must be run as root or via sudo." >&2
  exit 1
fi

touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

# ==== Run Commands as Root Helper ====
run() {
  "$@" >> "$LOG_FILE" 2>&1
}

# ==== Begin Logging ====
{
  echo ":: [$AGENT_NAME] Starting Wazuh agent enrollment ::"
  date
  echo "-----------------------------------------------"
} | tee -a "$LOG_FILE"

# ==== Cleanup ====
echo "[*] Removing any existing Wazuh agent..." | tee -a "$LOG_FILE"
run systemctl stop wazuh-agent || true
run apt-get -y purge wazuh-agent || true

# ==== Download ====
echo "[*] Downloading Wazuh agent $WAZUH_AGENT_VERSION..." | tee -a "$LOG_FILE"
curl -sSfL -o "${TMP_DIR}/${WAZUH_DEB}" \
  "https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/${WAZUH_DEB}" >> "$LOG_FILE" 2>&1

# ==== Install ====
echo "[*] Installing agent package..." | tee -a "$LOG_FILE"
run dpkg -i "${TMP_DIR}/${WAZUH_DEB}"

# ==== Patch config ====
if [[ -f "$CONF_FILE" ]]; then
  echo "[*] Setting manager address in config..." | tee -a "$LOG_FILE"
  run sed -i "s|<address>.*</address>|<address>${WAZUH_MANAGER}</address>|" "$CONF_FILE"
else
  echo "❌ Configuration file not found: $CONF_FILE" | tee -a "$LOG_FILE"
  exit 1
fi

# ==== Agent registration ====
echo "[*] Registering agent with Wazuh manager..." | tee -a "$LOG_FILE"
run /var/ossec/bin/agent-auth -m "$WAZUH_MANAGER" -A "$AGENT_NAME" -G "$WAZUH_GROUP"

# ==== Enable and start ====
echo "[*] Enabling and starting wazuh-agent..." | tee -a "$LOG_FILE"
run systemctl daemon-reexec
run systemctl enable wazuh-agent
run systemctl start wazuh-agent

# ==== Done ====
echo -e "\033[32m✔ [$AGENT_NAME] Enrollment complete.\033[0m" | tee -a "$LOG_FILE"
