#!/bin/bash

echo "Content-type: text/plain"
echo ""

if [ -f fetcher_pid.txt ]; then
    kill $(cat fetcher_pid.txt)
    rm fetcher_pid.txt
    echo "Fetcher process stopped."
else
    echo "No running fetcher process found."
fi

