#!/usr/bin/env bash
# Usage: run_linux_wave.sh <csv-file> <ssh-keyfile>

set -euo pipefail
CSV="$1"
KEY="$2"

echo -e "\n\033[34m:: Rolling out to Linux fleet ::\033[0m"

while IFS=',' read -r IP HOST USER GROUP EXTRA; do
  [[ -z "${IP// }" || "$IP" =~ ^# ]] && continue     # skip comments / blanks
  USER=${USER:-robot}

  echo -e "\033[36m➜  ${HOST:-$IP} ($IP) as $USER\033[0m"

  scp -o StrictHostKeyChecking=no -i "$KEY" \
      scripts/enroll_linux_agent.sh "${USER}@${IP}:/tmp/"

  ssh -o StrictHostKeyChecking=no -i "$KEY" \
      "${USER}@${IP}" \
      "bash /tmp/enroll_linux_agent.sh -g ${GROUP}"
done < "$CSV"
