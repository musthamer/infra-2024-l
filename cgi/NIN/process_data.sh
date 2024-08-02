#!/bin/bash

echo "Starting data processing loop..."

while true; do
    ./fetch_data.sh
    ./sort_data.sh
    ./insert_data.sh
    sleep 10
done

