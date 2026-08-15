#!/bin/bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "Bitte als root ausfuehren. Beispiel: sudo bash scripts/seed_demo_ais.sh"
    exit 1
fi

mysql -uroot infra-2024-l_db <<'SQL'
INSERT INTO ships (mmsi, timestamp, ship_name)
VALUES
    ('211111111', NOW(), 'Demo Vessel Alpha'),
    ('222222222', NOW(), 'Demo Vessel Beta')
ON DUPLICATE KEY UPDATE
    timestamp = VALUES(timestamp),
    ship_name = VALUES(ship_name);

DELETE FROM positions WHERE ship_mmsi IN ('211111111', '222222222');

INSERT INTO positions (ship_mmsi, latitude, longitude, timestamp)
VALUES
    ('211111111', 53.54210, 8.58300, NOW() - INTERVAL 50 MINUTE),
    ('211111111', 53.54310, 8.58400, NOW() - INTERVAL 20 MINUTE),
    ('211111111', 53.54410, 8.58500, NOW() - INTERVAL 2 MINUTE),
    ('211111111', 53.54510, 8.58600, NOW()),
    ('222222222', 53.54900, 8.57000, NOW() - INTERVAL 4 MINUTE),
    ('222222222', 53.55000, 8.57100, NOW() - INTERVAL 90 SECOND);
SQL

echo "Demo-AIS-Daten wurden in infra-2024-l_db eingefuegt."