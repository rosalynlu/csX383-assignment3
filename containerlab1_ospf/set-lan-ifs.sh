#!/bin/sh

sudo docker exec -d clab-pa3wan-lan1host ip link set eth1 up
sudo docker exec -d clab-pa3wan-lan1host ip addr add 172.16.1.2/24 dev eth1
sudo docker exec -d clab-pa3wan-lan1host ip route add 10.0.0.0/8 via 172.16.1.1 dev eth1
sudo docker exec -d clab-pa3wan-lan1host ip route add 172.16.2.0/24 via 172.16.1.1 dev eth1

sudo docker exec -d clab-pa3wan-lan2host ip link set eth1 up
sudo docker exec -d clab-pa3wan-lan2host ip addr add 172.16.2.2/24 dev eth1
sudo docker exec -d clab-pa3wan-lan2host ip route add 10.0.0.0/8 via 172.16.2.1 dev eth1
sudo docker exec -d clab-pa3wan-lan2host ip route add 172.16.1.0/24 via 172.16.2.1 dev eth1
