#!/bin/sh
iptables -F
iptables -t nat -F
iptables -X
iptables -t nat -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT


iptables -A INPUT -i lo -j ACCEPT


iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT



iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT   # SSH from external
iptables -A INPUT -i eth0 -p tcp --dport 80 -j ACCEPT   # Web server for firewall logs


iptables -A INPUT -i eth0 -p udp --dport 67:68 -j ACCEPT  # DHCP requests
iptables -A INPUT -i eth0 -p icmp -j ACCEPT  # Allow ICMP (ping)


iptables -A INPUT -i eth1 -j ACCEPT
iptables -A INPUT -i eth2 -j ACCEPT


iptables -t nat -A POSTROUTING -s 192.168.50.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.55.0/24 -o eth0 -j MASQUERADE



iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT  # LAN 50.x to Internet
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT  # Internet to LAN 50.x
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT  # LAN 55.x to Internet
iptables -A FORWARD -i eth0 -o eth2 -j ACCEPT  # Internet to LAN 55.x


iptables -N DROP_55_TO_50
iptables -A DROP_55_TO_50 -j LOG --log-prefix "FW_DROP_55to50 "
iptables -A DROP_55_TO_50 -j DROP


iptables -A FORWARD -s 192.168.50.0/24 -d 192.168.55.0/24 -p tcp -m conntrack --ctstate NEW -j ACCEPT


iptables -A FORWARD -s 192.168.55.0/24 -d 192.168.50.0/24 -p tcp -m conntrack --ctstate NEW -j DROP_55_TO_50


iptables -A FORWARD -s 192.168.50.0/24 -d 192.168.55.0/24 -p icmp -j ACCEPT
iptables -A FORWARD -s 192.168.55.0/24 -d 192.168.50.0/24 -p icmp -j ACCEPT


iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8822 -j DNAT --to-destination 192.168.55.100:22
iptables -A FORWARD -p tcp --dport 22 -d 192.168.55.100 -j ACCEPT


iptables-save > /etc/iptables/rules-save
