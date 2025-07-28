#!/bin/bash

# Force PATH to ensure sshpass is visible
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

CSV_FILE=""
SSH_KEY=""
SSH_USER=""
DEFAULT_PASS=""

print_help() {
  echo "Usage: $0 --csv <csv_file> --ssh-key <key_path> --ssh-user <username> [--password <default_password>]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --csv)
      CSV_FILE="$2"
      shift 2
      ;;
    --ssh-key)
      SSH_KEY="$2"
      shift 2
      ;;
    --ssh-user)
      SSH_USER="$2"
      shift 2
      ;;
    --password)
      DEFAULT_PASS="$2"
      shift 2
      ;;
    *)
      print_help
      ;;
  esac
done

if [[ -z "$CSV_FILE" || -z "$SSH_KEY" || -z "$SSH_USER" ]]; then
  print_help
fi

if [[ ! -f "$CSV_FILE" ]]; then
  echo "[ERROR] CSV file not found: $CSV_FILE"
  exit 1
fi

if [[ ! -f "$SSH_KEY" ]]; then
  echo "[ERROR] SSH key not found: $SSH_KEY"
  exit 1
fi

chmod 600 "$SSH_KEY"

while IFS=, read -r ip hostname user group; do
  [[ "$ip" =~ ^#.*$ || -z "$ip" ]] && continue

  echo "[INFO] Deploying SSH key to $hostname ($ip)"

  if [[ -n "$DEFAULT_PASS" ]]; then
    echo "[DEBUG] PATH is: $PATH"
    which sshpass || echo "[ERROR] sshpass still not found in PATH"
    /usr/bin/sshpass -p "$DEFAULT_PASS" ssh-copy-id -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$ip"
  else
    ssh-copy-id -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$ip"
  fi

done < "$CSV_FILE"
