#!/bin/bash
set -euo pipefail

# Default locations
CSV_FILE="csv/linux_targets.csv"
SSH_USER="robot"
SSH_KEY="$HOME/.ssh/id_rsa"

# Allow override via args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --csv)
      CSV_FILE="$2"
      shift 2
      ;;
    --ssh-user)
      SSH_USER="$2"
      shift 2
      ;;
    --ssh-key)
      SSH_KEY="$2"
      shift 2
      ;;
    *)
      echo "[ERROR] Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Launch main Linux install pipeline
echo "[INFO] Running full Linux rollout..."
bash scripts/install_agents.sh --csv "$CSV_FILE" --ssh-user "$SSH_USER" --ssh-key "$SSH_KEY"
