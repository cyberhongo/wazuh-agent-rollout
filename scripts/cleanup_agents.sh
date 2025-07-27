#!/bin/bash
# File: cleanup_agents.sh
# Purpose: Wipe agents from Wazuh Manager and uninstall them from Linux hosts

set -euo pipefail

AGENT_CTL="/var/ossec/bin/agent_control"
MANAGER_SSH_USER="robot"
LINUX_CSV="hosts/linux_agents.csv"

# Step 1: Remove all agents from manager
ALL_IDS=$($AGENT_CTL -l | awk 'NR>6 {print $2}' | grep -E '^[0-9]{3}$' || true)
echo "[INFO] Removing agents from manager..."
for ID in $ALL_IDS; do
  echo " - Removing agent ID $ID"
  $AGENT_CTL -r -u "$ID" || true
done

# Step 2: Cleanup queue
echo "[INFO] Cleaning manager queues..."
rm -rf /var/ossec/queue/{ossec,alerts/*,agent-info/*,agents/*,cluster/*,logcollector/*}

# Step 3: SSH uninstall from Linux agents
echo "[INFO] Uninstalling agents on Linux hosts..."
while IFS="," read -r HOSTNAME IP USER GROUP; do
  echo " - Uninstalling on $HOSTNAME ($IP)"
  ssh -o StrictHostKeyChecking=no "$USER@$IP" 'sudo systemctl stop wazuh-agent && sudo /var/ossec/uninstall.sh && sudo rm -rf /var/ossec/' || echo "   [WARN] Failed on $HOSTNAME"
done < <(tail -n +2 "$LINUX_CSV")

echo "[DONE] Cleanup complete. Ready for fresh installation."
