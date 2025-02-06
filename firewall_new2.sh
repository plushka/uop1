#!/bin/sh
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT

iptables -A INPUT   -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 80 -j ACCEPT

iptables -A INPUT -p udp --dport 67:68 -j ACCEPT

iptables -A INPUT  -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT


iptables -A INPUT -i eth1 -j ACCEPT
iptables -A INPUT -i eth2 -j ACCEPT


iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT

iptables -A FORWARD -s 192.168.50.0/24 -d 192.168.55.0/24 \
   -p tcp -m conntrack --ctstate NEW -j ACCEPT

iptables -A FORWARD -s 192.168.50.0/24 -d 192.168.55.0/24 -p icmp -j ACCEPT
iptables -A FORWARD -s 192.168.55.0/24 -d 192.168.50.0/24 -p icmp -j ACCEPT

iptables -N DROP_55_TO_50
iptables -A DROP_55_TO_50 -j LOG --log-prefix "FW_DROP_55to50: " --log-level 4
iptables -A DROP_55_TO_50 -j DROP
iptables -A FORWARD -s 192.168.55.0/24 -d 192.168.50.0/24 \
   -p tcp -m conntrack --ctstate NEW -j DROP_55_TO_50

iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8822 \
   -j DNAT --to-destination 192.168.55.100:22

iptables -A FORWARD -p tcp -d 192.168.55.100 --dport 22 \
   -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT

iptables-save > /etc/iptables/rules-save
