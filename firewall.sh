#!/bin/sh
iptables -F
iptables -t nat -F
iptables -X
iptables -t nat -X

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# --- INPUT pravidla ---
iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT   # (pokud chcete SSH zvenku)
iptables -A INPUT -i eth0 -p tcp --dport 80 -j ACCEPT   # web pro statistiku
iptables -A INPUT -i eth0 -j ACCEPT   # (případně pro ICMP, DHCP, atd.)

iptables -A INPUT -i eth1 -j ACCEPT
iptables -A INPUT -i eth2 -j ACCEPT

# --- FORWARD pravidla ---
iptables -t nat -A POSTROUTING -s 192.168.50.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.55.0/24 -o eth0 -j MASQUERADE

iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -j ACCEPT

iptables -N DROP_55_TO_50
iptables -A DROP_55_TO_50 -j LOG --log-prefix "FW_DROP_55to50 "
iptables -A DROP_55_TO_50 -j DROP

iptables -A FORWARD -s 192.168.50.0/24 -d 192.168.55.0/24 -p tcp -m state --state NEW -j ACCEPT

iptables -A FORWARD -s 192.168.55.0/24 -d 192.168.50.0/24 -p tcp -m state --state NEW -j DROP_55_TO_50

iptables-save > /etc/iptables/rules-save
