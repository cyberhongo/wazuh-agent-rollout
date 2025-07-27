#!/bin/bash

CSV_FILE="$1"
SSH_KEY="$2"

if [[ -z "$CSV_FILE" || -z "$SSH_KEY" ]]; then
  echo "Usage: $0 <csv_file> <ssh_private_key>"
  exit 1
fi

echo "[*] Setting up NOPASSWD sudo access for Wazuh installer..."

while IFS=, read -r ip hostname username group; do
  [[ "$ip" == "ip" ]] && continue

  echo "➡ Configuring sudo on $hostname ($ip)..."

  # Prompt once for this host's sudo password
  echo -n "🔐 Enter sudo password for $username@$ip: "
  read -s SUDOPASS
  echo

  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$username@$ip" bash -s <<EOF
echo "$SUDOPASS" | sudo -S bash -c '
echo "$username ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/wazuh-rollout &&
chmod 440 /etc/sudoers.d/wazuh-rollout'
EOF

  if [[ $? -eq 0 ]]; then
    echo "✅ $ip ($hostname): Sudo rule added successfully"
  else
    echo "❌ $ip ($hostname): Failed to apply sudo rule"
  fi

done < "$CSV_FILE"
