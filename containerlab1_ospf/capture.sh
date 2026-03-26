#!/bin/bash

set -e

mkdir -p outputs

for r in r1 r2 r3 r4 r5 r6; do
  docker exec -it clab-pa3wan-${r} vtysh -c "show ip route" > outputs/${r}_show_ip_route.txt
  docker exec -it clab-pa3wan-${r} vtysh -c "show ip ospf neighbor" > outputs/${r}_show_ip_ospf_neighbor.txt
  docker exec -it clab-pa3wan-${r} vtysh -c "show ip ospf database" > outputs/${r}_show_ip_ospf_database.txt
done

docker exec -it clab-pa3wan-lan1host traceroute 172.16.2.2 > outputs/lan1_to_lan2_traceroute.txt
