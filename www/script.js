window.onload = function() {
    checkLoginStatus();

    const baseURL = '/cgi-bin/project_2024';

    const accordion = document.getElementById('accordion');
    const groups = accordion.getElementsByClassName('group');

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
            }
        });
    }

    document.getElementById('register-form').addEventListener('submit', function(event) {
        event.preventDefault();
        const formData = new FormData(this);
        const params = new URLSearchParams();

        for (const pair of formData.entries()) {
            params.append(pair[0], pair[1]);
        }

        let xhr = new XMLHttpRequest();
        xhr.open('GET', `${baseURL}/register.sh?` + params.toString(), true);
        xhr.onload = function() {
            if (this.status === 200) {
                try {
                    const response = JSON.parse(this.responseText);
                    if (response.status === "success") {
                        alert("Registrierung Abgeschlossen");
                    } else {
                        alert("Registrierung Fehlgeschlagen: " + response.message);
                    }
                } catch (e) {
                    alert("Fehler beim Verarbeiten der Antwort: " + this.responseText);
                }
            } else {
                alert("Registrierung Fehlgeschlagen: " + this.responseText);
            }
        }
        xhr.send();
    });

    document.getElementById('login-form').addEventListener('submit', function(event) {
        event.preventDefault();
        const formData = new FormData(this);
        const params = new URLSearchParams();

        for (const pair of formData.entries()) {
            params.append(pair[0], pair[1]);
        }

        let xhr = new XMLHttpRequest();
        xhr.open('GET', `${baseURL}/login.sh?` + params.toString(), true);
        xhr.onload = function() {
            if (xhr.status === 200) {
                try {
                    const response = JSON.parse(this.responseText);
                    if (response.status === "success") {
                        document.getElementById('map-group').classList.remove('disabled');
                        document.getElementById('ships-group').classList.remove('disabled');
                        alert("Login erfolgreich!");
                    } else {
                        alert("Login Fehlgeschlagen: " + response.message);
                    }
                } catch (e) {
                    alert("Fehler beim Verarbeiten der Antwort: " + this.responseText);
                }
            } else {
                alert("Login Fehlgeschlagen: " + this.responseText);
            }
        };
        xhr.onerror = function() {
            alert("Anfragefehler: Bitte versuchen Sie es erneut.");
        };

        xhr.send();
    });

    function checkLoginStatus() {
        let xhr = new XMLHttpRequest();
        const baseURL = '/cgi-bin/project_2024';
        xhr.open('GET', `${baseURL}/check_session.sh`, true);
        xhr.onload = function() {
            if (xhr.status === 200) {
                try {
                    const response = JSON.parse(this.responseText);
                    if (response.status === "success") {
                        document.getElementById('map-group').classList.remove('disabled');
                        document.getElementById('ships-group').classList.remove('disabled');

                        // Load ships data initially and every 10 seconds
                        loadShipsData();
                        setInterval(loadShipsData, 10000);
                    }
                } catch (e) {
                    alert("Fehler beim Verarbeiten der Antwort: " + this.responseText);
                }
            } else {
                alert("Fehler bei der Überprüfung des Anmeldestatus");
            }
        };
        xhr.send();
    }

    let mapInitialized = false;
    function initializeMap() {
        const map = L.map('map').setView([53.54,8.5835], 17);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }).addTo(map);
        mapInitialized = true;
    }

    /*
    function loadShipsData() {
        let xhr = new XMLHttpRequest();
        xhr.open('GET', `${baseURL}/get_ships.sh`, true);
        xhr.onload = function() {
            if (xhr.status === 200) {
                try {
                    const ships = JSON.parse(this.responseText);
                    const tableBody = document.getElementById('ships-table').getElementsByTagName('tbody')[0];
                    tableBody.innerHTML = '';

                    ships.forEach(ship => {
                        const row = document.createElement('tr');
                        row.innerHTML = `
                            <td>${ship.name}</td>
                            <td>${ship.mmsi}</td>
                            <td>${ship.position}</td>
                            <td>${ship.timestamp}</td>
                        `;
                        tableBody.appendChild(row);
                    });
                } catch (e) {
                    alert("Fehler beim Verarbeiten der Antwort: " + this.responseText);
                }
            } else {
                alert("Fehler beim Laden der Schiffsdaten: " + xhr.responseText);
            }
        };
        xhr.send();
    }
    */

    /*
    function startFetcher() {
        let xhr = new XMLHttpRequest();
        xhr.open('GET', `${baseURL}/start_fetcher.sh`, true);
        xhr.onload = function() {
            if (xhr.status === 200) {
                alert("Fetcher-Prozess gestartet");
            } else {
                alert("Fehler beim Starten des Fetcher-Prozesses: " + xhr.responseText);
            }
        };
        xhr.send();
    }

    function stopFetcher() {
        let xhr = new XMLHttpRequest();
        xhr.open('GET', `${baseURL}/stop_fetcher.sh`, true);
        xhr.onload = function() {
            if (xhr.status === 200) {
                alert("Fetcher-Prozess gestoppt");
            } else {
                alert("Fehler beim Stoppen des Fetcher-Prozesses: " + xhr.responseText);
            }
        };
        xhr.send();
    }
    */
};

