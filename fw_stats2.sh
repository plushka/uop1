#!/bin/sh

LOGFILE="/var/log/messages"
STATEFILE="/var/lib/fw_drop_stats.db"
OUTPUT_FILE="/var/www/localhost/htdocs/fw_stats.html"

[ -f $STATEFILE ] || touch $STATEFILE

declare -A STATS


while read line; do
    IP=$(echo "$line" | cut -d' ' -f1)
    COUNT=$(echo "$line" | cut -d' ' -f2)
    STATS[$IP]=$COUNT
done < $STATEFILE


tail -n 1000 $LOGFILE | grep "FW_DROP_55to50" | while read l; do
    SRC=$(echo "$l" | sed -n 's/.*SRC=\([^ ]*\).*/\1/p')
    if [ -n "$SRC" ]; then
        STATS[$SRC]=$(( ${STATS[$SRC]} + 1 ))
    fi
done


> $STATEFILE
for IP in "${!STATS[@]}"; do
    echo "$IP ${STATS[$IP]}" >> $STATEFILE
done


echo "<html><head><title>Drop Stats</title></head><body>" > $OUTPUT_FILE
echo "<h1>Zahozené TCP NEW pakety z 55 -> 50</h1>" >> $OUTPUT_FILE
echo "<table border='1'><tr><th>Zdrojová IP</th><th>Počet</th></tr>" >> $OUTPUT_FILE

for IP in "${!STATS[@]}"; do
    echo "<tr><td>$IP</td><td>${STATS[$IP]}</td></tr>" >> $OUTPUT_FILE
done

echo "</table></body></html>" >> $OUTPUT_FILE
