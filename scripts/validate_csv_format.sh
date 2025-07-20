#!/bin/bash

CSV_FILE="$1"

if [[ ! -f "$CSV_FILE" ]]; then
  echo "❌ CSV file not found: $CSV_FILE"
  exit 1
fi

echo "[*] Validating format of $CSV_FILE..."

header=$(head -n1 "$CSV_FILE")
expected="ip,hostname,username,group"

if [[ "$header" != "$expected" ]]; then
  echo "❌ Invalid header in $CSV_FILE. Expected: $expected"
  exit 1
fi

awk -F',' 'NF != 4 { print "❌ Invalid row: " $0; bad=1 } END { exit bad }' "$CSV_FILE"
if [[ $? -ne 0 ]]; then
  echo "❌ CSV validation failed: $CSV_FILE"
  exit 1
fi

echo "✅ CSV format is valid: $CSV_FILE"
