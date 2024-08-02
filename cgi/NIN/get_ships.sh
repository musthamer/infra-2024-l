#!/bin/bash

echo "Content-type: application/json"
echo ""
source db_config.sh

query="SELECT name, mmsi, CONCAT(latitude, ', ', longitude) AS position, timestamp FROM ships"

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -sse "$query" | awk '
BEGIN {
    print "["
}
{
    printf "%s{\"name\":\"%s\", \"mmsi\":\"%s\", \"position\":\"%s\", \"timestamp\":\"%s\"}", separator, $1, $2, $3, $4
    separator = ","
}
END {
    print "]"
}'

