#!/bin/bash

echo "Content-type: text/plain"
echo ""

echo "Starting fetcher process..."
nohup ./process_data.sh > process_data.log 2>&1 &
if [ $? -eq 0 ]; then
    echo $! > fetcher_pid.txt
    echo "Fetcher process started with PID $!"
else
    echo "Error starting fetcher process."
fi

