#!/bin/bash
set -euo pipefail
CSV_FILE="$1"
KEY_PATH="$2"
LOG_FILE="linux_wave_$(date +%Y%m%d_%H%M%S).log"

echo ":: Rolling out to Linux fleet ::" | tee -a "$LOG_FILE"
echo "Processing: IP=$IP, HOST=$HOST, USER=$USER, GROUP=$GROUP"
while IFS=',' read -r IP HOST USER GROUP <<< "$line"; do
    [[ "$HOSTNAME" =~ ^#|^$ ]] && continue

    USER=${USER:-robot}
    echo -e "\n➜  $HOSTNAME ($IP) as $USER" | tee -a "$LOG_FILE"

    scp -i "$KEY_PATH" -o StrictHostKeyChecking=no scripts/enroll_linux_agent.sh "${USER}@${IP}:/tmp/" | tee -a "$LOG_FILE"
    echo "➡️  $IP ($HOST) as $USER"
    echo "DEBUG: PRIVKEY = $PRIVKEY"
    echo "DEBUG: USER = $USER"
    echo "DEBUG: IP = $IP"

    ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no "${USER}@${IP}" "chmod +x /tmp/enroll_linux_agent.sh && sudo /tmp/enroll_linux_agent.sh $GROUP" | tee -a "$LOG_FILE"

done < "$CSV_FILE"
