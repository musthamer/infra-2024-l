window.onload = function() {
    const baseURL = new URL('../../cgi-bin/project_2024', window.location.href).pathname.replace(/\/$/, '');
    const query = new URLSearchParams(window.location.search);
    const mockMode = query.get('mock') === '1';

    const userInfo = document.getElementById('user-info');
    const username = document.getElementById('username');
    const mapGroup = document.getElementById('map-group');
    const shipsGroup = document.getElementById('ships-group');
    const shipsContent = document.getElementById('ships-content');
    const registerForm = document.getElementById('register-form');
    const loginForm = document.getElementById('login-form');
    const logoutButton = document.getElementById('logout-button');

    const accordion = document.getElementById('accordion');
    const groups = accordion.getElementsByClassName('group');

    let shipsPollTimer = null;
    let shipsRequestInFlight = false;
    let lastShipsUpdate = 0;
    let latestShipsPayload = null;
    let mapInitialized = false;
    let map = null;
    let markersLayer = null;
    let tracksLayer = null;

    const shipMarkers = new Map();
    const shipTracks = new Map();
    const shipTrackPoints = new Map();
    const mockFrames = createMockFrames();
    let mockFrameIndex = 0;

    function escapeHtml(value) {
        return String(value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function buildShipsTable(ships) {
        if (!ships.length) {
            shipsContent.innerHTML = '<p>Keine aktiven Schiffe in den letzten 5 Minuten gefunden.</p>';
            return;
        }

        const rows = ships.map((ship) => {
            const time = new Date(ship.timestamp * 1000).toLocaleTimeString('de-DE');
            return `
                <tr data-mmsi="${escapeHtml(ship.mmsi)}">
                    <td>${escapeHtml(ship.ship_name || ship.mmsi)}</td>
                    <td>${escapeHtml(ship.mmsi)}</td>
                    <td>${Number(ship.latitude).toFixed(5)}</td>
                    <td>${Number(ship.longitude).toFixed(5)}</td>
                    <td>${escapeHtml(time)}</td>
                </tr>`;
        }).join('');

        shipsContent.innerHTML = `
            <table>
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>MMSI</th>
                        <th>Breite</th>
                        <th>Länge</th>
                        <th>Letzte Position</th>
                    </tr>
                </thead>
                <tbody>${rows}</tbody>
            </table>`;
    }

    function createMockFrames() {
        const now = Math.floor(Date.now() / 1000);

        return [
            {
                status: 'success',
                implementation: 'optimized',
                user_email: 'mock.user@example.com',
                server_time: now,
                ships: [
                    { mmsi: '211111111', ship_name: 'Mock Vessel Alpha', latitude: 53.5451, longitude: 8.5860, timestamp: now },
                    { mmsi: '222222222', ship_name: 'Mock Vessel Beta', latitude: 53.5500, longitude: 8.5710, timestamp: now - 10 }
                ],
                tracks: [
                    { mmsi: '211111111', ship_name: 'Mock Vessel Alpha', points: [
                        { latitude: 53.5435, longitude: 8.5840, timestamp: now - 200 },
                        { latitude: 53.5442, longitude: 8.5850, timestamp: now - 90 },
                        { latitude: 53.5451, longitude: 8.5860, timestamp: now }
                    ]},
                    { mmsi: '222222222', ship_name: 'Mock Vessel Beta', points: [
                        { latitude: 53.5488, longitude: 8.5695, timestamp: now - 240 },
                        { latitude: 53.5500, longitude: 8.5710, timestamp: now - 10 }
                    ]}
                ]
            },
            {
                status: 'success',
                implementation: 'optimized',
                user_email: 'mock.user@example.com',
                server_time: now + 1,
                ships: [
                    { mmsi: '211111111', ship_name: 'Mock Vessel Alpha', latitude: 53.5460, longitude: 8.5870, timestamp: now + 1 }
                ],
                tracks: [
                    { mmsi: '211111111', ship_name: 'Mock Vessel Alpha', points: [
                        { latitude: 53.5435, longitude: 8.5840, timestamp: now - 200 },
                        { latitude: 53.5442, longitude: 8.5850, timestamp: now - 90 },
                        { latitude: 53.5451, longitude: 8.5860, timestamp: now },
                        { latitude: 53.5460, longitude: 8.5870, timestamp: now + 1 }
                    ]}
                ]
            }
        ];
    }

    function trimTrackPoints(points) {
        const oneHourAgo = Math.floor(Date.now() / 1000) - 3600;
        return points.filter((point) => point.timestamp >= oneHourAgo);
    }

    function syncMapData(payload) {
        if (!mapInitialized || !payload) {
            return;
        }

        const activeMmsi = new Set(payload.ships.map((ship) => ship.mmsi));

        for (const ship of payload.ships) {
            const markerText = `<strong>${escapeHtml(ship.ship_name || ship.mmsi)}</strong><br>MMSI: ${escapeHtml(ship.mmsi)}`;
            if (!shipMarkers.has(ship.mmsi)) {
                const marker = L.marker([ship.latitude, ship.longitude]).addTo(markersLayer);
                marker.bindPopup(markerText);
                shipMarkers.set(ship.mmsi, marker);
            } else {
                const marker = shipMarkers.get(ship.mmsi);
                marker.setLatLng([ship.latitude, ship.longitude]);
                marker.setPopupContent(markerText);
            }
        }

        for (const [mmsi, marker] of shipMarkers.entries()) {
            if (!activeMmsi.has(mmsi)) {
                markersLayer.removeLayer(marker);
                shipMarkers.delete(mmsi);
            }
        }

        const payloadTracks = new Map(payload.tracks.map((track) => [track.mmsi, track]));

        for (const ship of payload.ships) {
            const track = payloadTracks.get(ship.mmsi);
            const existingPoints = shipTrackPoints.get(ship.mmsi) || [];
            let mergedPoints = existingPoints;

            if (track && track.points.length) {
                if (lastShipsUpdate === 0) {
                    mergedPoints = track.points.slice();
                } else {
                    const lastKnownTimestamp = existingPoints.length ? existingPoints[existingPoints.length - 1].timestamp : 0;
                    const additionalPoints = track.points.filter((point) => point.timestamp > lastKnownTimestamp);
                    mergedPoints = existingPoints.concat(additionalPoints);
                }
            }

            mergedPoints = trimTrackPoints(mergedPoints);
            shipTrackPoints.set(ship.mmsi, mergedPoints);

            const latLngs = mergedPoints.map((point) => [point.latitude, point.longitude]);
            if (!shipTracks.has(ship.mmsi)) {
                const polyline = L.polyline(latLngs, { color: '#1d4ed8', weight: 3 }).addTo(tracksLayer);
                shipTracks.set(ship.mmsi, polyline);
            } else {
                shipTracks.get(ship.mmsi).setLatLngs(latLngs);
            }
        }

        for (const [mmsi, polyline] of shipTracks.entries()) {
            if (!activeMmsi.has(mmsi)) {
                tracksLayer.removeLayer(polyline);
                shipTracks.delete(mmsi);
                shipTrackPoints.delete(mmsi);
            }
        }
    }

    function applyShipsPayload(payload) {
        latestShipsPayload = payload;
        buildShipsTable(payload.ships || []);
        syncMapData(payload);
        lastShipsUpdate = payload.server_time || Math.floor(Date.now() / 1000);
    }

    function postForm(url, params, onDone) {
        const xhr = new XMLHttpRequest();
        xhr.open('POST', url, true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        xhr.onload = function() {
            onDone(xhr.status, xhr.responseText);
        };
        xhr.onerror = function() {
            onDone(0, '');
        };
        xhr.send(params.toString());
    }

    function getNextMockPayload() {
        const frame = mockFrames[mockFrameIndex % mockFrames.length];
        mockFrameIndex += 1;
        return JSON.parse(JSON.stringify(frame));
    }

    function fetchShips() {
        if (shipsRequestInFlight) {
            return;
        }

        if (mockMode) {
            applyShipsPayload(getNextMockPayload());
            return;
        }

        let url = `${baseURL}/ships.sh?implementation=optimized`;
        if (lastShipsUpdate > 0) {
            url += `&since=${encodeURIComponent(lastShipsUpdate)}`;
        }

        shipsRequestInFlight = true;
        const xhr = new XMLHttpRequest();
        xhr.open('GET', url, true);
        xhr.onload = function() {
            shipsRequestInFlight = false;

            if (xhr.status === 401) {
                setLoggedOutState();
                return;
            }

            if (xhr.status !== 200) {
                return;
            }

            try {
                const response = JSON.parse(xhr.responseText);
                if (response.status === 'success') {
                    applyShipsPayload(response);
                }
            } catch (error) {
                console.error('Fehler beim Verarbeiten der Schiffsdaten', error);
            }
        };
        xhr.onerror = function() {
            shipsRequestInFlight = false;
        };
        xhr.send();
    }

    function startShipsPolling() {
        if (shipsPollTimer) {
            return;
        }
        fetchShips();
        shipsPollTimer = setInterval(fetchShips, 1000);
    }

    function stopShipsPolling() {
        if (shipsPollTimer) {
            clearInterval(shipsPollTimer);
            shipsPollTimer = null;
        }
    }

    function setLoggedInState(email) {
        username.textContent = email || '';
        userInfo.classList.remove('hidden');
        userInfo.style.display = 'flex';
        mapGroup.classList.remove('disabled');
        shipsGroup.classList.remove('disabled');
        startShipsPolling();
    }

    function setLoggedOutState() {
        userInfo.classList.add('hidden');
        userInfo.style.display = 'none';
        mapGroup.classList.add('disabled');
        shipsGroup.classList.add('disabled');
        username.textContent = '';
        latestShipsPayload = null;
        lastShipsUpdate = 0;
        stopShipsPolling();
        shipsContent.innerHTML = '';

        shipMarkers.forEach((marker) => markersLayer && markersLayer.removeLayer(marker));
        shipMarkers.clear();
        shipTracks.forEach((polyline) => tracksLayer && tracksLayer.removeLayer(polyline));
        shipTracks.clear();
        shipTrackPoints.clear();
    }

    function restoreSession() {
        if (mockMode) {
            setLoggedInState('mock.user@example.com');
            return;
        }

        let xhr = new XMLHttpRequest();
        xhr.open('GET', `${baseURL}/verify_session.sh`, true);
        xhr.onload = function() {
            if (xhr.status !== 200) {
                setLoggedOutState();
                return;
            }

            try {
                const response = JSON.parse(xhr.responseText);
                if (response.status === 'success') {
                    setLoggedInState(response.user_email);
                } else {
                    setLoggedOutState();
                }
            } catch (e) {
                setLoggedOutState();
            }
        };
        xhr.onerror = setLoggedOutState;
        xhr.send();
    }

    setLoggedOutState();
    restoreSession();

    for (let i = 0; i < groups.length; i++) {
        groups[i].getElementsByTagName('h3')[0].addEventListener('click', function() {
          const content = groups[i].getElementsByClassName('content')[0];
            if (content.style.display === 'block') {
                content.style.display = 'none';
            } else {
                for (let j = 0; j < groups.length; j++) {
                    groups[j].getElementsByClassName('content')[0].style.display = 'none';
                }
                content.style.display = 'block';
                if (groups[i].id === 'map-group' && !mapInitialized) {
                    initializeMap();
                }
                if (groups[i].id === 'ships-group' && latestShipsPayload) {
                    buildShipsTable(latestShipsPayload.ships || []);
                }
            }
        });
    }

    registerForm.addEventListener('submit', function(e) {
       e.preventDefault();
        const formData = new FormData(this);
        const params = new URLSearchParams();

        for (const pair of formData.entries()) {
            params.append(pair[0], pair[1]);
        }

        postForm(`${baseURL}/register.sh`, params, function(status, body) {
            if (status !== 200) {
                alert('Registrierung Fehlgeschlagen');
                return;
            }

            try {
                const response = JSON.parse(body);
                if (response.status === 'success') {
                    alert('Registrierung abgeschlossen');
                } else {
                    alert('Registrierung fehlgeschlagen: ' + response.message);
                }
            } catch (e) {
                alert('Fehler beim Verarbeiten der Antwort');
            }
        });
    });

    loginForm.addEventListener('submit', function(event) {
        event.preventDefault();
        const formData = new FormData(this);
        const params = new URLSearchParams();

        for (const pair of formData.entries()) {
            params.append(pair[0], pair[1]);
        }

        postForm(`${baseURL}/login.sh`, params, function(status, body) {
            if (status !== 200) {
                alert('Login fehlgeschlagen');
                return;
            }

            try {
                const response = JSON.parse(body);
                if (response.status === 'success') {
                    setLoggedInState(response.user_email || formData.get('emailLogin'));
                    alert('Login erfolgreich');
                } else {
                    alert('Login fehlgeschlagen: ' + response.message);
                }
            } catch (e) {
                alert('Fehler beim Verarbeiten der Antwort');
            }
        });
    });

    logoutButton.addEventListener('click', function() {
        const params = new URLSearchParams();
        postForm(`${baseURL}/logout.sh`, params, function(status) {
            if (status === 200) {
                alert('Sie wurden erfolgreich abgemeldet.');
            }

            setLoggedOutState();
            for (let i = 1; i < groups.length; i++) {
                groups[i].getElementsByClassName('content')[0].style.display = 'none';
            }
            groups[0].getElementsByClassName('content')[0].style.display = 'block';
        });
    });


    function initializeMap() {
        map = L.map('map').setView([53.54,8.5835], 11);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }).addTo(map);
        markersLayer = L.layerGroup().addTo(map);
        tracksLayer = L.layerGroup().addTo(map);
        mapInitialized = true;
        if (latestShipsPayload) {
            syncMapData(latestShipsPayload);
        }
    }
};

