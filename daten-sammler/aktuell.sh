   #!/usr/bin/env bash
  
   #Schiffs-Daten-Pfad
   DATA_FILE="data.csv"
  
   # Output-Datei wo die gefilterten Daten der letzten 5 Minuten gespeichert werden
   OUTPUT_FILE="aktuell.csv"


TEMP_FILE="temp.csv"


  # Daten vor 5 Minuten ausgeben lassen und speichern lassen
  ZEIT_VORHER=$(date --date="5 minutes ago" +"%Y-%m-%d %H:%M:%S")
  > "$OUTPUT_FILE"  #wird immer geelert und wieder gespeichert (nur die letzten 5 Min)
 
 
  tail -n 1000 "$DATA_FILE" | while IFS= read -r line; do
      timestamp=$(echo "$line" | cut -d ' ' -f 1-2)  # Annahme: Zeitstempel ist in den ersten beiden Feldern
      if [[ "$timestamp" > "$ZEIT_VORHER" ]]; then
          echo "$line" >> "$OUTPUT_FILE"
      fi
  done
  
# Sortieren der gefilterten Daten und speichern in TEMP_FILE
cat "$OUTPUT_FILE" | cut -d "|" -f 1,3,5,9,10 | sort > "$TEMP_FILE"

# Verschieben der sortierten Daten zurück in OUTPUT_FILE
mv "$TEMP_FILE" "$OUTPUT_FILE"

  echo "Die aktuellen Daten der letzten 5 Minuten wurden in $OUTPUT_FILE gespeichert."
