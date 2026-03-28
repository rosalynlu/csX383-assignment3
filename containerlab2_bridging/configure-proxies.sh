#!/usr/bin/env bash
set -euo pipefail

LAB=clab-pa3bridges

echo "Configuring socat proxies for bridge HIL..."

# c2edge: listen on bridge IP, forward to C2 inventory
docker exec -d ${LAB}-c2edge socat TCP-LISTEN:30081,fork,reuseaddr TCP:172.16.2.99:30081
docker exec -d ${LAB}-c2edge socat TCP-LISTEN:30557,fork,reuseaddr TCP:172.16.2.99:30557
echo "  c2edge: gRPC+ZMQ -> 172.16.2.99"

# each proxy: listen on management IP, forward to c2edge via bridge network
for proxy in breadproxy dairyproxy meatproxy produceproxy partyproxy; do
  docker exec -d ${LAB}-${proxy} socat TCP-LISTEN:30081,fork,reuseaddr TCP:192.168.50.10:30081
  docker exec -d ${LAB}-${proxy} socat TCP-LISTEN:30557,fork,reuseaddr TCP:192.168.50.10:30557
  echo "  ${proxy}: gRPC+ZMQ -> c2edge (192.168.50.10) via bridge"
done

echo ""
echo "Done. Now run expose-proxies.sh ON team-ras-1 to expose ports to K8s:"
echo "  ssh team-ras-1 'bash ~/expose-proxies.sh'"
