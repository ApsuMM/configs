#!/bin/sh

# configure interfaces
RED="eth0"
BLUE="eth1"
INT_IP=`ip -4 addr show $RED | grep -oP '(?<=inet\s)\d+(\.\d+){3}'`

# enable routing
echo 1 > /proc/sys/net/ipv4/ip_forward

cat <<EOF | iptables-save > /etc/sysconfig/iptables 

:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]

# clear existing rules and add default policies
iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

# accept loopback traffic
iptables -A INPUT -i lo -j ACCEPT

# accept traffic from blue site
iptables -A INPUT -i $BLUE -j ACCEPT

# accept icmp on red site
iptables -A INPUT -i $RED -d $INT_IP -p icmp -j ACCEPT

# accept established connections
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# route local outbound traffic
iptables -A FORWARD -i $BLUE -o $RED -d 192.168.128.0/17 -j ACCEPT
iptables -A FORWARD -i $BLUE -o $RED -d 10.3.16.0/24 -j ACCEPT

# route local inbound traffic
iptables -A FORWARD -i $RED -o $BLUE -d 192.168.172.0/24 -p icmp -j ACCEPT

# add statefull NAT
iptables -t nat -A POSTROUTING -o $RED -j MASQUERADE --random

# Allow traffic from internal to external
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT

# Allow returning traffic from external to internal
iptables -A FORWARD -i eth1 -o eth0 -m conntrack --ctstate RELATED, ESTABLISHED -j ACCEPT

# Drop all other traffic that shouldn't be forwarded
iptables -A FORWARD -j DROP
EOF

systemctl enable --now iptables




