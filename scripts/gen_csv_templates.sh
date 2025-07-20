#!/bin/bash
mkdir -p csv

echo "HOSTNAME,IP,USER,GROUP" > csv/linux_targets.csv
echo "HOSTNAME,IP,USER,GROUP" > csv/windows_targets.csv

echo "# Add targets in the format:" >> csv/linux_targets.csv
echo "# ubuntu-01,192.168.1.10,robot,lucid-linux" >> csv/linux_targets.csv

echo "# Add targets in the format:" >> csv/windows_targets.csv
echo "# WIN-SRV01,192.168.1.100,administrator,lucid-windows" >> csv/windows_targets.csv

echo "✅ CSV templates generated in ./csv/"
