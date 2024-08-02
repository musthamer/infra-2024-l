#!/bin/bash

echo "Content-type: text/html"
echo ""
echo "<html><head><title>Ship Data</title></head><body>"
echo "<h1>Ship Data</h1>"
echo "<table border='1'>"
echo "<tr><th>Name</th><th>MMSI</th><th>Position</th><th>Timestamp</th></tr>"

data=$(./get_ships.sh)
echo "$data" | jq -r '.[] | "<tr><td>\(.name)</td><td>\(.mmsi)</td><td>\(.position)</td><td>\(.timestamp)</td></tr>"'

echo "</table>"
echo "</body></html>"

