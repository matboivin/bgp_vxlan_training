#!/bin/sh
# Configure router 2 for Part 2 Unicast
LOCAL_IP="192.168.2.2"
PEER_IP="192.168.2.1"

# Configure IP address on eth0
/sbin/ip addr add $LOCAL_IP/24 dev eth0

# Create VXLAN tunnel
/sbin/ip link add name vxlan10 type vxlan id 10 dstport 4789 local $LOCAL_IP remote $PEER_IP dev eth0
# Up VXLAN tunnel
/sbin/ip link set dev vxlan10 up

# Create bridge
/sbin/ip link add br0 type bridge
# Up bridge
/sbin/ip link set dev br0 up

# Attach interfaces to bridge
/sbin/ip link set vxlan10 master br0
/sbin/ip link set eth1 master br0
