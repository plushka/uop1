#!/bin/sh

LOGFILE="/var/log/messages"
STATEFILE="/var/lib/fw_drop_stats.db"
OUTPUT_FILE="/var/www/html/fw_stats.html"
TMP_FILE="/tmp/fw_drop_tmp.db"

[ -f $STATEFILE ] || touch $STATEFILE


> $TMP_FILE


while read IP COUNT; do
    echo "$IP $COUNT" >> $TMP_FILE
done < $STATEFILE

tail -n 1000 $LOGFILE | grep "FW_DROP_55to50" | while read l; do
    SRC=$(echo "$l" | sed -n 's/.*SRC=\([^ ]*\).*/\1/p')
    if [ -n "$SRC" ]; then
        grep -q "^$SRC " $TMP_FILE && \
            sed -i "/^$SRC /s/[0-9]\+$/$(($(grep "^$SRC " $TMP_FILE | awk '{print $2}') + 1))/" $TMP_FILE || \
            echo "$SRC 1" >> $TMP_FILE
    fi
done


mv $TMP_FILE $STATEFILE


echo "<html><head><title>Drop Stats</title></head><body>" > $OUTPUT_FILE
echo "<h1>Zahozené TCP NEW pakety z 55 -> 50</h1>" >> $OUTPUT_FILE
echo "<table border='1'><tr><th>Zdrojová IP</th><th>Počet</th></tr>" >> $OUTPUT_FILE

while read IP COUNT; do
    echo "<tr><td>$IP</td><td>$COUNT</td></tr>" >> $OUTPUT_FILE
done < $STATEFILE

echo "</table></body></html>" >> $OUTPUT_FILE
