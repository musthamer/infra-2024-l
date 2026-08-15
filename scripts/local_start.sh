#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
SITE_CONF="/etc/apache2/sites-available/infra-2024-l-local.conf"
PORTS_CONF="/etc/apache2/ports.conf"

if [ "${EUID}" -ne 0 ]; then
    echo "Bitte als root ausfuehren. Beispiel: sudo bash scripts/local_start.sh"
    exit 1
fi

service mariadb start

mysql -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`infra-2024-l_db\`;
CREATE USER IF NOT EXISTS 'infra-2024-l'@'localhost' IDENTIFIED BY 'aqsfm6hUFhvub99ORFrG';
CREATE USER IF NOT EXISTS 'infra-2024-l'@'127.0.0.1' IDENTIFIED BY 'aqsfm6hUFhvub99ORFrG';
GRANT ALL PRIVILEGES ON \`infra-2024-l_db\`.* TO 'infra-2024-l'@'localhost';
GRANT ALL PRIVILEGES ON \`infra-2024-l_db\`.* TO 'infra-2024-l'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL

mysql -uroot infra-2024-l_db < "$REPO_ROOT/config/initdata.sql"

if ! grep -q '^Listen 8080$' "$PORTS_CONF"; then
    printf '\nListen 8080\n' >> "$PORTS_CONF"
fi

cat > "$SITE_CONF" <<EOF
<VirtualHost *:8080>
    ServerName localhost
    DocumentRoot $REPO_ROOT/www

    SetEnv DB_HOST 127.0.0.1
    SetEnv DB_USER infra-2024-l
    SetEnv DB_PASS aqsfm6hUFhvub99ORFrG
    SetEnv DB_NAME infra-2024-l_db
    SetEnv APP_COOKIE_PATH /
    SetEnv SESSION_TTL_SECONDS 28800
    SetEnv EMAIL_QUEUE_HOST 127.0.0.1
    SetEnv EMAIL_QUEUE_PORT 4000

    <Directory $REPO_ROOT/www>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ScriptAlias /cgi-bin/project_2024/ $REPO_ROOT/cgi/

    <Directory $REPO_ROOT/cgi>
        Options +ExecCGI
        AllowOverride None
        AddHandler cgi-script .sh
        Require all granted
    </Directory>

    DirectoryIndex index.html
    ErrorLog \${APACHE_LOG_DIR}/infra-2024-l-error.log
    CustomLog \${APACHE_LOG_DIR}/infra-2024-l-access.log combined
</VirtualHost>
EOF

find "$REPO_ROOT/cgi" -type f -name '*.sh' -exec chmod +x {} +

a2enmod cgid headers >/dev/null
a2ensite infra-2024-l-local >/dev/null
service apache2 restart

bash "$REPO_ROOT/scripts/services_start.sh" >/dev/null 2>&1 || true

echo "Projekt laeuft lokal unter: http://localhost:8080/"
echo "CGI Endpoint Basis: http://localhost:8080/cgi-bin/project_2024/"
echo "Workuser Services: bash scripts/services_status.sh"