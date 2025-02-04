#!/bin/sh
LOGFILE="/var/log/messages"
STATEFILE="/var/lib/fw_drop_stats.db"
TMP="/tmp/fw_drop_stats.tmp"

[ -f $STATEFILE ] || touch $STATEFILE


declare -A STATS
while read line; do
    IP=$(echo "$line" | cut -d' ' -f1)
    COUNT=$(echo "$line" | cut -d' ' -f2)
    STATS[$IP]=$COUNT
done < $STATEFILE

tail -n 1000 $LOGFILE | grep "FW_DROP_55to50" | while read l; do
    # V logu to bývá např. "... SRC=192.168.55.X DST=192.168.50.Y ..."
    SRC=$(echo "$l" | sed -n 's/.*SRC=\([^ ]*\).*/\1/p')
    if [ -n "$SRC" ]; then
        # Zvýšíme čítač
        if [ -z "${STATS[$SRC]}" ]; then
            STATS[$SRC]=0
        fi
        STATS[$SRC]=$(( ${STATS[$SRC]} + 1 ))
    fi
done

> $STATEFILE
for IP in "${!STATS[@]}"; do
    echo "$IP ${STATS[$IP]}" >> $STATEFILE
done
