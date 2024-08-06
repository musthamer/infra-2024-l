  1 #!/usr/bin/env bash
  2
  3 #Schiffs-Daten-Pfad
  4 DATA_FILE="data.csv"
  5
  6 #Hier kommt noch die Sortier-Befehle- Datum Uhrzeit | platz | MMSI | Status |
  7
  8 # Output-Datei wo die gefilterten Daten der letzten 5 Minuten gespeichert werden
  9 OUTPUT_FILE="aktuell.csv"
 10
 11 # Daten vor 5 Minuten ausgeben lassen und speichern lassen
 12 ZEIT_VORHER=$(date --date="5 minutes ago" +"%Y-%m-%d %H:%M:%S")
 13 > "$OUTPUT_FILE"  #wird immer geelert und wieder gespeichert (nur die letzten 5 Min)
 14
 15
 16 tail -n 1000 "$DATA_FILE" | while IFS= read -r line; do
 17     timestamp=$(echo "$line" | cut -d ' ' -f 1-2)  # Annahme: Zeitstempel ist in den ersten beiden Feldern
 18     if [[ "$timestamp" > "$ZEIT_VORHER" ]]; then
 19         echo "$line" >> "$OUTPUT_FILE"
 20     fi
 21 done
 22
 23 echo "Die aktuellen Daten der letzten 5 Minuten wurden in $OUTPUT_FILE gespeichert."
