# INFRA 2024-L Project

Robuste INFRA-Semesteraufgabe mit den geforderten Technologien:
HTML, CSS, JavaScript, AJAX, Leaflet, MariaDB, Bash CGI und Git.

## 0. What this project is (quick overview)

This repository is a complete university INFRA project for a ship-tracking web app.

Main focus:

- secure login/session flow via Bash CGI + MariaDB
- live ship monitoring on a Leaflet map
- synchronized ship table updated via AJAX
- interchangeable endpoint implementations (simple and optimized)
- asynchronous email simulation pipeline (TCP server, queue, worker, watcher)

In short: this project demonstrates frontend, backend, database, async processing,
service supervision, testing, load testing, and monitoring in one stack.

## 0.1 How it works end-to-end

1. User opens the web UI and signs in.
2. CGI login validates credentials, creates session cookie, and returns JSON.
3. Frontend polls ships endpoint every second.
4. Ships endpoint returns active ships (5 min) and tracks (1 hour).
5. Frontend updates map markers, polylines, and HTML table incrementally.
6. After successful login, a TCP job is sent to the workuser queue.
7. Worker processes queue jobs and writes simulated email results.
8. Watcher keeps TCP server and worker alive by restarting crashed processes.

## 0.2 If someone downloads this project

Use this exact sequence from a fresh clone.

### Clone

```bash
git clone <repo-url>
cd infra-2024-l
```

### Start local runtime (host mode)

Requirements: Linux/WSL environment with Apache + MariaDB installed.

```bash
sudo bash scripts/local_start.sh
bash scripts/services_status.sh
bash scripts/services_health.sh
```

Open the app:

```text
http://localhost:8080/
```

Register a user in the UI, then login.

### Optional: seed demo ships for instant map/table data

```bash
sudo bash scripts/seed_demo_ais.sh
```

### Optional Docker start

```bash
docker compose up -d --build
docker compose ps
```

### Run full automated checks

```bash
bash scripts/run_all_tests.sh
cat tests/results_matrix.csv
```

### Stop

```bash
sudo bash scripts/local_stop.sh
bash scripts/services_stop.sh
```

## 1. Ziel

Die Anwendung bietet:

- Registrierung, Login, Session-Verwaltung und Logout
- Leaflet-Karte mit aktiven Schiffen (letzte 5 Minuten)
- Schiffsrouten (letzte 60 Minuten)
- Synchronisierte HTML-Tabelle
- Zwei austauschbare CGI-Implementierungen fuer denselben Endpunkt
- Simuliertes E-Mail-Subsystem nach jedem erfolgreichen Login
- Workuser TCP-Server + Queue + Worker + Watcher
- Lasttests und Monitoring mit CSV und Gnuplot

## 2. Technologie-Stack

- Frontend: HTML, CSS, JavaScript, AJAX, Leaflet
- Backend: Bash CGI unter Apache
- Datenbank: MariaDB
- Service-Layer: Bash TCP-Protokoll, Queue in MariaDB, Worker, Watcher
- Betrieb: lokale Skripte, optional Docker Compose
- Versionskontrolle: Git

## 3. Verzeichnisstruktur

- cgi: alle CGI-Endpunkte und gemeinsame Funktionen
- www: Frontend (Accordion, Karte, Tabelle, Polling, Mock-Modus)
- scripts: Start/Stop/Status, Queue/TCP/Worker/Watcher, Tests, Lasttests
- config/initdata.sql: Schema, Queue-Tabelle, Indizes
- monitoring: CSV-Metriken, Gnuplot-Skripte und generierte Grafiken
- runtime: Laufzeitdateien (PIDs, Logs, Locks) zur Service-Ueberwachung
- docker und docker-compose.yml: optionale Container-Ausfuehrung

## 4. Voraussetzungen

Lokaler Host:

- Apache mit CGI-Modul
- MariaDB
- bash
- curl
- ncat oder kompatibles nc
- optional gnuplot fuer Diagramme

## 5. Lokales Setup

### 5.1 Start

Als root:

```bash
bash scripts/local_start.sh
```

Damit werden Datenbank/Apache vorbereitet, CGI bereitgestellt und Workuser-Services gestartet.

### 5.2 Service-Status

```bash
bash scripts/services_status.sh
bash scripts/services_health.sh
```

### 5.3 Stop / Restart

```bash
bash scripts/local_stop.sh
bash scripts/local_restart.sh
bash scripts/services_restart.sh
```

## 6. Authentifizierung und Sessions

Implementiert:

- Registrierung ueber POST
- Login ueber POST
- Session-Cookie (HttpOnly, SameSite=Lax)
- Session-Validierung und Session-Restore nach Refresh
- Logout mit Cookie-Loeschung
- Session-Ablaufzeit (Standard 8 Stunden)
- Bereinigung abgelaufener Sessions

Sicherheitsaspekte:

- Eingabevalidierung (E-Mail, Parameter)
- SQL-Escaping in Bash
- Keine Passwort-Ausgabe
- Strukturierte JSON-Fehlerantworten

Passwortstrategie:

- Neue Konten nutzen SHA-512-crypt via openssl (wenn verfuegbar)
- Legacy-Hashes bleiben login-kompatibel
- Legacy-Hashes werden bei erfolgreichem Login auf neues Format hochgezogen

## 7. Ship/AIS und Polling

Endpunkte:

- cgi/ships.sh
- cgi/ships_simple.sh
- cgi/ships_optimized.sh

Regeln:

- Aktiv: Position in den letzten 5 Minuten
- Track: Positionen der aktiven Schiffe aus den letzten 60 Minuten
- Bei 0 aktiven Schiffen: ships leer und tracks leer

Polling:

- etwa 1 Request pro Sekunde
- Schutz gegen doppelte Timer
- Schutz gegen ueberlappende Requests
- Aktualisierung von Markern und Polylines ohne Layer-Duplikate
- Entfernen inaktiver Schiffe und alter Trackpunkte

### Frontend ohne Backend

Mock-Modus:

```text
http://localhost:8080/?mock=1
```

Im Mock-Modus werden Tabellen- und Kartenupdates mit lokalen Fixtures simuliert.

## 8. Interchangeable CGI

Einheitlicher Wrapper:

- ships.sh?implementation=simple
- ships.sh?implementation=optimized

Beide liefern denselben JSON-Vertrag, gleiche Auth-Regeln und gleiches fachliches Ergebnis.

Optimierung:

- Optimized-Version legt Latest-Position-Auswahl in MariaDB ab
- Simple-Version bleibt bewusst lesbar

## 9. E-Mail-Simulation, Queue und TCP-Protokoll

Nach jedem erfolgreichen Login:

1. Login erstellt Session
2. Login sendet Queue-Job per TCP
3. Workuser TCP-Server validiert Request und schreibt Job in MariaDB
4. Worker verarbeitet Jobs und schreibt Simulationslog
5. Login liefert Erfolg auch dann, wenn Queue kurz nicht verfuegbar ist (Queue-Status im JSON)

Protokoll:

- Request: V1|COMMAND|JOB_ID|PAYLOAD
- Beispiel Command: ENQUEUE_EMAIL
- Response ACK: ACK|V1|JOB_ID|QUEUED
- Response ERROR: ERR|V1|JOB_ID|ERROR_TEXT

Keine Ausfuehrung von Netzwerk-Input via eval.

## 10. Workuser Service-Supervision

Services:

- TCP server
- Email worker
- Watcher

Watcher-Funktion:

- prueft laufende Prozesse ueber PID-Dateien
- startet gestoppte Prozesse automatisch neu
- Lock-Dateien verhindern doppelte Instanzen

Wichtige Skripte:

- scripts/services_start.sh
- scripts/services_stop.sh
- scripts/services_restart.sh
- scripts/services_status.sh
- scripts/services_health.sh
- scripts/services_recover.sh

## 11. Cleanup alter AIS-Positionen

Skript:

- scripts/cleanup_old_positions.sh

Standard-Retention:

- 7200 Sekunden (2 Stunden)

Bereinigung betrifft ausschliesslich positions-Zeilen.
Ship-Metadaten bleiben erhalten.

## 12. Tests

### 12.1 Hauptsuite

```bash
bash scripts/run_all_tests.sh
cat tests/results_matrix.csv
```

Abgedeckte Checks:

- Registrierung
- Login Erfolg/Fehler
- Session-Validierung
- Unauth Zugriff auf Ships
- Simple/Optimized Ergebnisgleichheit
- Invalid implementation und invalid since
- TCP Protokoll und Queue
- AIS Cleanup
- Session Expiration
- DB Failure Verhalten

### 12.2 Zusatztests

```bash
bash scripts/test_auth_and_ships.sh
bash scripts/test_tcp_queue.sh
bash scripts/check_login_queue_flow.sh
```

## 13. Lasttests

### Benutzer-Last

```bash
bash scripts/load_test_login.sh
```

CSV-Ausgabe:

- monitoring/login_load.csv

### Queue-Last

```bash
bash scripts/load_test_queue.sh
```

CSV-Ausgabe:

- monitoring/queue_load.csv

### Throughput-Zeitreihe

```bash
DURATION_SECONDS=30 bash scripts/collect_throughput_metrics.sh
```

CSV-Ausgabe:

- monitoring/requests.csv

## 14. Monitoring mit Gnuplot

```bash
bash scripts/generate_gnuplot.sh
```

Erzeugte Grafiken:

- monitoring/login_load.png
- monitoring/queue_load.png
- monitoring/throughput.png

Falls gnuplot fehlt, gibt das Skript die notwendigen Kommandos aus.

## 15. Deployment

### Host-basiert

- scripts/local_start.sh
- scripts/services_status.sh

### Docker Compose

```bash
docker compose up -d --build
docker compose ps
```

Compose enthaelt:

- db (MariaDB)
- web (Apache + CGI)
- workuser (TCP + Worker + Watcher, restart unless-stopped, Healthcheck)

## 16. Security und Robustheit

Umgesetzt:

- Backend-Auth-Block fuer ships Endpunkte (401 + JSON)
- Strict since Validierung
- Strukturierte DB-Fehlerantworten (500 + JSON)
- Verbesserte Header/JSON-Konsistenz
- Reduzierung unsicherer Eval-Nutzung
- Eingabevalidierung fuer E-Mail/Job-ID/Timestamps

## 17. Demo-Daten

Bekannte Demo-MMSI:

- 211111111
- 222222222

Skripte arbeiten absichtlich nur auf diesen Demo-Daten:

- scripts/seed_demo_ais.sh
- scripts/set_demo_ship_inactive.sh

## 18. Troubleshooting

- Falls Services mehrfach gestartet wurden:

```bash
bash scripts/services_recover.sh
```

- Falls Queue nicht antwortet:

```bash
bash scripts/services_health.sh
cat runtime/logs/protocol.log
```

- Falls Karte/Tabelle leer ist:

```bash
bash scripts/seed_demo_ais.sh
```

## 19. Bekannte Grenzen

- Service-Lifecycle ist lokal host-gebunden; bei Host-Shutdown sind Dienste offline.
- Persistenz ueber Terminal-Schliessung ist gegeben, ueber Host-Stromausfall nicht.
- Fuer Remote-Unabhaengigkeit muss auf einen dauerhaft laufenden Server deployt werden.
- Queue-Latenzwerte sind umgebungsabhaengig.
