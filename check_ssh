#!/bin/sh

TARGET_IP="192.168.55.100"
TARGET_PORT="22"
EXT_PORT="8822"

nc -z -w1 $TARGET_IP $TARGET_PORT 2>/dev/null
if [ $? -eq 0 ]; then
  iptables -t nat -C PREROUTING -i eth0 -p tcp --dport $EXT_PORT -j DNAT --to-destination $TARGET_IP:$TARGET_PORT 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "Port je dostupný – přidávám DNAT na port $EXT_PORT."
    iptables -t nat -A PREROUTING -i eth0 -p tcp --dport $EXT_PORT -j DNAT --to-destination $TARGET_IP:$TARGET_PORT
  fi
else
  echo "Port není dostupný – mažu DNAT pravidlo (pokud existuje)."
  iptables -t nat -D PREROUTING -i eth0 -p tcp --dport $EXT_PORT -j DNAT --to-destination $TARGET_IP:$TARGET_PORT 2>/dev/null
fi
