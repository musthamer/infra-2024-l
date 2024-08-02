#!/bin/bash

echo "Fetching data from rhodes and saving to file..."
ncat rhodes 8082 > data.txt
echo "Data fetched and saved to data.txt"

