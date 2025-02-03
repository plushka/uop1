#!/bin/sh

# Vyčištění
iptables -F
iptables -t nat -F
iptables -X
iptables -t nat -X

# Politiky
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Povolíme loopback
iptables -A INPUT -i lo -j ACCEPT

# Povolíme "established,related" na INPUT i FORWARD
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# --- INPUT pravidla ---
# Povolíme příchozí DHCP klient a DNS (podle potřeby)
# Povolíme SSH a web pro rozhraní eth0
iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT   # (pokud chcete SSH zvenku)
iptables -A INPUT -i eth0 -p tcp --dport 80 -j ACCEPT   # web pro statistiku
iptables -A INPUT -i eth0 -j ACCEPT   # (případně pro ICMP, DHCP, atd.)

# Povolíme plný přístup z vnitřních sítí
iptables -A INPUT -i eth1 -j ACCEPT
iptables -A INPUT -i eth2 -j ACCEPT

# --- FORWARD pravidla ---
# NAT pro vnitřní sítě -> internet (přes eth0)
iptables -t nat -A POSTROUTING -s 192.168.50.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.55.0/24 -o eth0 -j MASQUERADE

# Povolíme forward z eth1 do eth0
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT
# Povolíme forward z eth2 do eth0
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -j ACCEPT

# Směrování mezi sítěmi 50 a 55 s omezením:
# - nová spojení povolit jen ze sítě 50 do 55
# - opačným směrem to blokovat

# Nejprve logování pokusů (abychom měli statistiku)
iptables -N DROP_55_TO_50
iptables -A DROP_55_TO_50 -j LOG --log-prefix "FW_DROP_55to50 "
iptables -A DROP_55_TO_50 -j DROP

# Forward z 50 do 55 - nová spojení povolíme
iptables -A FORWARD -s 192.168.50.0/24 -d 192.168.55.0/24 -p tcp -m state --state NEW -j ACCEPT

# Forward z 55 do 50 - nová spojení házíme do DROP řetězce
iptables -A FORWARD -s 192.168.55.0/24 -d 192.168.50.0/24 -p tcp -m state --state NEW -j DROP_55_TO_50

# Uložení (pokud používáte iptables-save)
iptables-save > /etc/iptables/rules-save
