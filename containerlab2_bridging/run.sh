#!/usr/bin/env bash
set -euo pipefail

containerlab deploy -t pa3bridges.clab.yaml
sleep 3

bash ./configure-bridges.sh
bash ./configure-hosts.sh

sleep 15

for ip in 192.168.50.21 192.168.50.22 192.168.50.23 192.168.50.24 192.168.50.25; do
  docker exec clab-pa3bridges-c2edge ping -c 2 -W 1 "$ip" >/dev/null || true
done

echo
echo "Bridge lab is up."
echo "Run:"
echo "  docker ps | grep clab-pa3bridges"
echo "  ./capture.sh"
