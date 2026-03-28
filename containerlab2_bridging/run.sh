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

bash ./configure-proxies.sh

echo
echo "Bridge lab is up."
echo "Next steps:"
echo "  1. Copy expose-proxies.sh to team-ras-1 and run it:"
echo "       scp expose-proxies.sh team-ras-1:~/ && ssh team-ras-1 'bash ~/expose-proxies.sh'"
echo "  2. Apply updated K8s robot deployments:"
echo "       kubectl apply -f ../k8s/robot-bread-c3.yaml (etc.)"
echo "  3. Run ./capture.sh to collect outputs"
