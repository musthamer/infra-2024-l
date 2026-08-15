#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/db_config.sh"
source "$SCRIPT_DIR/common.sh"

if [ "${REQUEST_METHOD:-GET}" = "POST" ]; then
    read_request_body >/dev/null
fi

firstname=$(get_request_param_any firstname || true)
lastname=$(get_request_param_any lastname || true)
email=$(get_request_param_any email || true)
phonenumber=$(get_request_param_any phonenumber || true)
password=$(get_request_param_any password || true)

if [ -z "$firstname" ] || [ -z "$lastname" ] || [ -z "$password" ] || ! valid_email "$email"; then
    print_json_header "400 Bad Request"
    print_json "error" "Invalid registration data"
    exit 0
fi

if [ "${#password}" -lt 8 ]; then
    print_json_header "400 Bad Request"
    print_json "error" "Password too short"
    exit 0
fi

password_hash=$(generate_password_hash "$password")
escaped_firstname=$(sql_escape "$firstname")
escaped_lastname=$(sql_escape "$lastname")
escaped_email=$(sql_escape "$email")
escaped_phone=$(sql_escape "$phonenumber")
escaped_password_hash=$(sql_escape "$password_hash")

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B -e "
    INSERT INTO users (firstname, lastname, email, password, phone)
    VALUES ('$escaped_firstname', '$escaped_lastname', '$escaped_email', '$escaped_password_hash', '$escaped_phone');
" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    print_json_header
    print_json "success" "Registrierung erfolgreich"
else
    print_json_header "400 Bad Request"
    print_json "error" "Fehler bei der Registrierung"
fi


