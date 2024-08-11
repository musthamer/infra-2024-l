#!/usr/bin/env bash

# Schiffs-Daten-Pfad
DATA_FILE="data.csv"

# Output-Datei wo die gefilterten Daten der letzten 5 Minuten gespeichert werden
OUTPUT_FILE="aktuell.csv"

# Temporäre Datei für Zwischenspeicherung
TEMP_FILE="temp.csv"

# Daten vor 5 Minuten ausgeben lassen und speichern lassen
ZEIT_VORHER=$(date --date="5 minutes ago" +"%Y-%m-%d %H:%M:%S")
> "$OUTPUT_FILE"  # wird immer geleert und wieder gespeichert (nur die letzten 5 Min)

tail -n 1000 "$DATA_FILE" | while IFS= read -r line; do
    timestamp=$(echo "$line" | cut -d ' ' -f 1-2)  # Annahme: Zeitstempel ist in den ersten beiden Feldern
  if [[ "$timestamp" > "$ZEIT_VORHER" ]]; then
        zeit=$(echo "$line" | cut -d "|" -f 1)
        mmsi=$(echo "$line" | cut -d "|" -f 3)
        name=$(echo "$line" | cut -d "|" -f 5)
        position=$(echo "$line" | cut -d "|" -f 7)
        longitude=$(echo "$line" | cut -d "|" -f 9)
        latitude=$(echo "$line" | cut -d "|" -f 10)
        echo "$zeit|$mmsi|$name|$position|$longitude|$latitude" >> "$OUTPUT_FILE"
    fi
done


#eine andere methode 
# Sortieren der gefilterten Daten und speichern in TEMP_FILE
#cat "$OUTPUT_FILE" | cut -d "|" -f 1,3,5,9,10 | sort > "$TEMP_FILE"
# Verschieben der sortierten Daten zurück in OUTPUT_FILE
#mvi "$TEMP_FILE" "$OUTPUT_FILE"


mariadb -e "
CREATE TABLE IF NOT EXISTS neu (
    Timestamp VARCHAR(20),
    MMSI BIGINT,
    name VARCHAR(20),
    NavigationalStatus VARCHAR(255),
    Longitude DECIMAL(10,6),
    Latitude DECIMAL(10,6)
);
"
cat "$OUTPUT_FILE" | while IFS="|" read -r timestamp mmsi name position longitude latitude; do
    mariadb -e "
    INSERT INTO neu (Timestamp, MMSI, name,NavigationalStatus, Longitude, Latitude)
    VALUES ('$timestamp', $mmsi, $name ,'$position', $longitude, $latitude);
    "
done


  echo "Die aktuellen Daten der letzten 5 Minuten wurden in $OUTPUT_FILE gespeichert."
