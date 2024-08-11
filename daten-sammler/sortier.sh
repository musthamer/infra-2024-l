#!/bin/bash

# Extrahieren der Uhrzeit, MMSI, Schiffsstatus und Position, dann sortieren nach Uhrzeit und MMSI
cat aktuell.csv | cut -d "|" -f 1,3,5,7,8,9,10 | sort > sort.csv

# Lesen der letzten Zeile, um Zielort, Längen- und Breitengrad sowie Geschwindigkeit zu erhalten
destination=$(tail -1 sort.csv |cut -d "|" -f 7)
longitude=$(tail -1 sort.csv | cut -d "|" -f 6)
latitude=$(tail -1 sort.csv | cut -d "|" -f 5)
speed=$(tail -1 sort.csv | cut -d "|" -f 1)

# Ausgabe der gesammelten Daten
echo "Destination: $destination"
echo "Longitude: $longitude"
echo "Latitude: $latitude"
echo "Speed: $speed"

