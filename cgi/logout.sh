#!/bin/bash

echo "Content-Type: text/plain"
echo ""

# Debugging: Überprüfung des Cookie-Inhalts
echo "DEBUG: HTTP_COOKIE = $HTTP_COOKIE"

# Session-ID aus dem Cookie extrahieren
cookieline=$(echo "$HTTP_COOKIE" | tr ";" "\n" | grep "^session_id=")
session_id=$(echo "$cookieline" | cut -d "=" -f 2)

# Debugging: Überprüfung der extrahierten Session-ID
echo "DEBUG: session_id extrahiert = $session_id"

if [ -n "$session_id" ]; then
    source db_config.sh

    # Session aus der Datenbank löschen
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    DELETE FROM sessions WHERE session_id = '$session_id';
    "

    # Debugging: Überprüfung der Anzahl betroffener Zeilen
    if [ $? -eq 0 ]; then
        echo "Set-Cookie: session_id=; Path=/docker-infra-2024-l-web/; Expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly"
        echo "Abmeldung erfolgreich"
    else
        echo "Fehler beim Löschen der Session."
    fi
else
    echo "Fehler: Keine gültige Sitzung gefunden."
fi
