#!/bin/bash

echo "Sorting data by ship name..."
sort -t '|' -k 3,3 data.txt -o sorted_data.txt
echo "Data sorted and saved to sorted_data.txt"

