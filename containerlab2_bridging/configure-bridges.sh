#!/usr/bin/env bash
set -euo pipefail

LAB=clab-pa3bridges

make_bridge() {
  local node="$1"
  local priority="$2"
  shift 2
  local ports=("$@")

  docker exec "${LAB}-${node}" sh -lc '
    set -e
    ip link del br0 2>/dev/null || true
    ip link add name br0 type bridge stp_state 1
    ip link set dev br0 up
  '

  for p in "${ports[@]}"; do
    docker exec "${LAB}-${node}" sh -lc "
      set -e
      ip link set dev ${p} up
      ip link set dev ${p} master br0
    "
  done

  docker exec "${LAB}-${node}" sh -lc "
    set -e
    ip link set dev br0 type bridge priority ${priority}
  "
}

make_bridge br1 4096  eth1 eth2 eth3 eth4
make_bridge br2 8192  eth1 eth2 eth3 eth4 eth5
make_bridge br3 12288 eth1 eth2 eth3 eth4
make_bridge br4 16384 eth1 eth2 eth3 eth4 eth5

docker exec ${LAB}-br1 sh -lc '
  bridge link set dev eth1 cost 2
  bridge link set dev eth2 cost 10
  bridge link set dev eth3 cost 25
  bridge link set dev eth4 cost 50
'

docker exec ${LAB}-br2 sh -lc '
  bridge link set dev eth1 cost 10
  bridge link set dev eth2 cost 5
  bridge link set dev eth3 cost 10
  bridge link set dev eth4 cost 2
  bridge link set dev eth5 cost 2
'

docker exec ${LAB}-br3 sh -lc '
  bridge link set dev eth1 cost 25
  bridge link set dev eth2 cost 5
  bridge link set dev eth3 cost 30
  bridge link set dev eth4 cost 2
'

docker exec ${LAB}-br4 sh -lc '
  bridge link set dev eth1 cost 50
  bridge link set dev eth2 cost 10
  bridge link set dev eth3 cost 30
  bridge link set dev eth4 cost 2
  bridge link set dev eth5 cost 2
'

echo "Bridges configured with STP and weighted path costs."
