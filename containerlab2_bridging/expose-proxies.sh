#!/usr/bin/env bash
# Run this ON team-ras-1 to expose clab proxy containers to K8s Cluster 3.
# Each proxy gets its own host port so each robot traverses a different bridge path.
#
# Port mapping (team-ras-1 172.16.6.164):
#   breadproxy   gRPC=31081  ZMQ=31557  -> clab mgmt 172.20.20.13
#   dairyproxy   gRPC=31082  ZMQ=31558  -> clab mgmt 172.20.20.9
#   meatproxy    gRPC=31083  ZMQ=31559  -> clab mgmt 172.20.20.4
#   produceproxy gRPC=31084  ZMQ=31560  -> clab mgmt 172.20.20.11
#   partyproxy   gRPC=31085  ZMQ=31561  -> clab mgmt 172.20.20.5

set -euo pipefail

# Kill any previous expose-proxies socat processes
pkill -f "socat TCP-LISTEN:310[0-9][0-9]" 2>/dev/null || true
pkill -f "socat TCP-LISTEN:315[0-9][0-9]" 2>/dev/null || true
sleep 1

declare -A MGMT_IPS=(
  [breadproxy]=172.20.20.13
  [dairyproxy]=172.20.20.9
  [meatproxy]=172.20.20.4
  [produceproxy]=172.20.20.11
  [partyproxy]=172.20.20.5
)

declare -A GRPC_PORTS=(
  [breadproxy]=31081
  [dairyproxy]=31082
  [meatproxy]=31083
  [produceproxy]=31084
  [partyproxy]=31085
)

declare -A ZMQ_PORTS=(
  [breadproxy]=31557
  [dairyproxy]=31558
  [meatproxy]=31559
  [produceproxy]=31560
  [partyproxy]=31561
)

for proxy in breadproxy dairyproxy meatproxy produceproxy partyproxy; do
  ip=${MGMT_IPS[$proxy]}
  grpc=${GRPC_PORTS[$proxy]}
  zmq=${ZMQ_PORTS[$proxy]}

  nohup socat TCP-LISTEN:${grpc},fork,reuseaddr TCP:${ip}:30081 >/tmp/socat-${proxy}-grpc.log 2>&1 &
  nohup socat TCP-LISTEN:${zmq},fork,reuseaddr  TCP:${ip}:30557 >/tmp/socat-${proxy}-zmq.log  2>&1 &
  echo "  ${proxy}: 172.16.6.164:${grpc} (gRPC)  172.16.6.164:${zmq} (ZMQ)"
done

echo ""
echo "All proxy ports live on 172.16.6.164. Apply updated K8s robot deployments next."
