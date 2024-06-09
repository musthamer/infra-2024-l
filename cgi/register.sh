#!/bin/bash
echo "Content-type: application/json"
echo ""
source db_config.sh
# Debugging-Informationen
echo "QUERY_STRING: $QUERY_STRING" >&2
# Lesen der QUERY_STRING
IFS='&' read -r -a params <<< "$QUERY_STRING"
declare -A data
for param in "${params[@]}"; do
    IFS='=' read -r -a pair <<< "$param"
    data["${pair[0]}"]="${pair[1]}"
done
# Debugging-Informationen
echo "Daten nach dem Parsen: ${data[@]}" >&2
echo "Aktion: ${data[action]}" >&2

if [ "${data[action]}" == "register" ]; then
    username="${data[username]}"
    password="${data[password]}"
    # Hashing des Passworts
    password_hash=$(echo -n "$password" | sha256sum | awk '{print $1}')
    # Einfügen des Benutzers in die Datenbank
    result=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "INSERT INTO users (username, password_hash) VALUES ('$username', '$password_hash');" 2>&1)
    if [ $? -eq 0 ]; then
        echo "{\"status\":\"success\",\"message\":\"User registered successfully.\"}"
    else
        echo "{\"status\":\"error\",\"message\":\"$result\"}"
    fi
else
    echo "{\"status\":\"error\",\"message\":\"Invalid action.\"}"
fi
