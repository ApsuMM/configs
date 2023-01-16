#!/bin/sh

# configure interfaces
RED="enp0s3"
BLUE="enp0s8"
EXT_IP=`ip -4 addr show $RED | grep -oP '(?<=inet\s)\d+(\.\d+){3}'`
INT_IP=`ip -4 addr show $BLUE | grep -oP '(?<=inet\s)\d+(\.\d+){3}'`
DNS="192.168.172.1"


# enable routing
echo 1 > /proc/sys/net/ipv4/ip_forward

# clear existing rules and add default policies
iptables -X
iptables -F
iptables -t nat -F
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# forward dns queries
iptables -t nat -A PREROUTING -i $RED -p udp --dport 53 -j DNAT --to-destination $DNS
iptables -t nat -A PREROUTING -i $RED -p tcp --dport 53 -j DNAT --to-destination $DNS
iptables -A FORWARD -i $RED -p udp -m udp --dport 53 -j ACCEPT
iptables -A FORWARD -i $RED -p tcp -m tcp --dport 53 -j ACCEPT
iptables -t nat -A POSTROUTING -o $RED -p udp --sport 53 -j SNAT --to-source $EXT_IP
iptables -t nat -A POSTROUTING -o $RED -p tcp --sport 53 -j SNAT --to-source $EXT_IP
# allow routing of external icmp traffic
iptables -A FORWARD -i $RED -o $BLUE -d 192.168.172.0/24 -p icmp -j ACCEPT
# allow traffic from internal to external
iptables -A FORWARD -i $BLUE -o $RED -j ACCEPT
# allow returning traffic from external to internal
iptables -A FORWARD -i $RED -o $BLUE -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# accept loopback traffic
iptables -A INPUT -i lo -j ACCEPT
# accept traffic from blue site
iptables -A INPUT -i $BLUE -j ACCEPT
# accept icmp on red site
iptables -A INPUT -i $RED -d $EXT_IP -p icmp -j ACCEPT
# accept established connections
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
# allow rip traffic
iptables -A INPUT -i $RED -p udp -m udp --dport 520 -j ACCEPT

# add custom NAT rules
iptables -t nat -A POSTROUTING -d 10.3.16.0/24 -j ACCEPT
iptables -t nat -A POSTROUTING -d 192.168.172.0/24 -j ACCEPT
iptables -t nat -A POSTROUTING -o $RED -j MASQUERADE --random

iptables-save > /etc/iptables/rules.v4





