#!/bin/sh

HOST="192.168.55.100"
PORT="22"
EXTERNAL_PORT="8822"
DNAT_RULE_EXISTS=$(iptables -t nat -S PREROUTING | grep "$EXTERNAL_PORT" | grep "$HOST:$PORT")
nc -z -w 2 $HOST $PORT
if [ $? -eq 0 ]; then
  if [ -z "$DNAT_RULE_EXISTS" ]; then
    echo "Port 22 on $HOST is open. Adding DNAT for port $EXTERNAL_PORT..."
    iptables -t nat -A PREROUTING -i eth0 -p tcp --dport $EXTERNAL_PORT -j DNAT --to-destination $HOST:$PORT
    iptables -A FORWARD -p tcp -d $HOST --dport $PORT -j ACCEPT
    iptables-save > /etc/iptables/rules-save
  fi
else
  if [ -n "$DNAT_RULE_EXISTS" ]; then
    echo "Port 22 on $HOST is closed. Removing DNAT for port $EXTERNAL_PORT..."
    iptables -t nat -F PREROUTING
    iptables -t nat -A POSTROUTING -s 192.168.50.0/24 -o eth0 -j MASQUERADE
    iptables -t nat -A POSTROUTING -s 192.168.55.0/24 -o eth0 -j MASQUERADE
    
    iptables-save > /etc/iptables/rules-save
  fi
fi
