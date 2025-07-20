#!/bin/bash
set -euo pipefail

EXPECTED_HEADER="HOSTNAME,IP,USER,GROUP"
FILE="$1"

echo "[*] Validating format of $FILE..."

if ! [[ -f "$FILE" ]]; then
  echo "❌ ERROR: File not found: $FILE"
  exit 1
fi

HEADER=$(head -n1 "$FILE" | tr -d '\r')
if [[ "$HEADER" != "$EXPECTED_HEADER" ]]; then
  echo "❌ ERROR: Expected header: $EXPECTED_HEADER"
  echo "📌 Found header:    $HEADER"
  exit 1
fi

tail -n +2 "$FILE" | while IFS=',' read -r HOSTNAME IP USER GROUP; do
  [[ "$HOSTNAME" =~ ^#|^$ ]] && continue
  if [[ -z "$IP" || -z "$GROUP" ]]; then
    echo "⚠️  Invalid line: $HOSTNAME,$IP,$USER,$GROUP"
    exit 1
  fi
done

echo "✅ CSV format is valid: $FILE"
