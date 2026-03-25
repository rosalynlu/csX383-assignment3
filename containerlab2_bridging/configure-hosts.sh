#!/usr/bin/env bash
set -euo pipefail

LAB=clab-pa3bridges

set_ip() {
  local node="$1"
  local ip="$2"
  docker exec "${LAB}-${node}" sh -lc "
    set -e
    ip link set dev eth1 up
    ip addr flush dev eth1 || true
    ip addr add ${ip}/24 dev eth1
  "
}

set_ip c2edge       192.168.50.10
set_ip breadproxy   192.168.50.21
set_ip dairyproxy   192.168.50.22
set_ip meatproxy    192.168.50.23
set_ip produceproxy 192.168.50.24
set_ip partyproxy   192.168.50.25

echo "Hosts configured on 192.168.50.0/24."
