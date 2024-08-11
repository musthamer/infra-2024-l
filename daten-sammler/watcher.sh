#!/usr/bin/env bash

rhodescheck=$(cat rhodes-last.txt)
rhodesvergleich=$(cat data.csv | wc -l)

if test "$rhodescheck" -eq "$rhodesvergleich" ; then
sleep 30
kill $(cat rhodes.pid) &>/dev/null
ncat -e readwrite.sh rhodes 8082 &
echo "$!" > rhodes.pid

fi

echo "$rhodesvergleich" > rhodes-last.txt
