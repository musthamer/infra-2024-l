#!/usr/bin/env bash

# Dateipfade
DATA_FILE="/home/kasrashrash/daten-sammler-aktuell/data.csv"
OUTPUT_FILE="aktuell.csv"
DATUM=$(date)

# Zeitstempel für die letzten 5 Minuten
ZEIT_VORHER=$(date --date="5 minutes ago" +"%Y-%m-%d %H:%M:%S")

# Temporäre Datei leeren oder erstellen
> "$OUTPUT_FILE"

# Daten filtern und in die Ausgabedatei schreiben
while IFS='|' read -r timestamp unbekannt1 mmsi unbekannt2 name unbekannt3 position unbekannt4 longitude latitude unbekannt5 unbekannt6 unbekannt7 unbekannt8 unbekannt9 unbekannt10; do
  # Prüfen, ob der Zeitstempel in den letzten 5 Minuten liegt
  if [[ "$timestamp" > "$ZEIT_VORHER" ]]; then
    # Formatierte Zeile in die Ausgabedatei schreiben
    echo "$timestamp|$mmsi|$name|$position|$longitude|$latitude" >> "$OUTPUT_FILE"
  fi
done < "$DATA_FILE"

# Ausgabe zur Bestätigung
echo "$DATUM Daten wurden gefiltert und in $OUTPUT_FILE gespeichert."

