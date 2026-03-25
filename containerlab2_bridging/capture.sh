#!/usr/bin/env bash
set -euo pipefail

LAB=clab-pa3bridges
OUT=outputs
mkdir -p "$OUT"

for ip in 192.168.50.21 192.168.50.22 192.168.50.23 192.168.50.24 192.168.50.25; do
  docker exec ${LAB}-c2edge ping -c 2 -W 1 "$ip" >/dev/null || true
done

for br in br1 br2 br3 br4; do
  {
    echo "===== ${br}: bridge link show ====="
    docker exec ${LAB}-${br} bridge link show
    echo
    echo "===== ${br}: MAC learning / FDB ====="
    docker exec ${LAB}-${br} bridge fdb show br br0
    echo
    echo "===== ${br}: bridge details ====="
    docker exec ${LAB}-${br} ip -d link show br0
  } > "${OUT}/${br}_bridge_state.txt"
done

for h in c2edge breadproxy dairyproxy meatproxy produceproxy partyproxy; do
  {
    echo "===== ${h}: ip addr ====="
    docker exec ${LAB}-${h} ip addr show dev eth1
    echo
    echo "===== ${h}: ARP / neighbor table ====="
    docker exec ${LAB}-${h} ip neigh show
  } > "${OUT}/${h}_arp.txt"
done

{
  echo "===== Connectivity tests from c2edge ====="
  for ip in 192.168.50.21 192.168.50.22 192.168.50.23 192.168.50.24 192.168.50.25; do
    echo "--- ping $ip ---"
    docker exec ${LAB}-c2edge ping -c 2 -W 1 "$ip" || true
    echo
  done
} > "${OUT}/connectivity.txt"

echo "Saved outputs in ${OUT}/"
