#!/bin/bash

echo "Content-type: text/plain"
echo ""
source db_config.sh

echo "Inserting sorted data into the database..."

process_data() {
    while IFS='|' read -r timestamp id mmsi status1 status2 status3 status4 lon lat course speed status5 status6 status7 status8 status9 status10; do
        if [[ $lon =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && [[ $lat =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
            INSERT INTO ships (timestamp, ship_id, mmsi, status1, status2, status3, status4, lon, lat, course, speed, status5, status6, status7, status8, status9, status10)
            VALUES ('$timestamp', '$id', '$mmsi', '$status1', '$status2', '$status3', '$status4', '$lon', '$lat', '$course', '$speed', '$status5', '$status6', '$status7', '$status8', '$status9', '$status10');
            " 2>&1 | tee -a insert_data.log
            echo "Inserted: $timestamp, $id, $mmsi, $status1, $status2, $status3, $status4, $lon, $lat, $course, $speed, $status5, $status6, $status7, $status8, $status9, $status10"
        else
            echo "Skipping invalid entry: $timestamp, $id, $mmsi, $status1, $status2, $status3, $status4, $lon, $lat, $course, $speed, $status5, $status6, $status7, $status8, $status9, $status10"
        fi
    done
}

process_data < sorted_data.txt

