window.onload = function() {

    const baseURL = '/docker-infra-2024-l-web/cgi-bin/project_2024';

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

    document.getElementById('register-form').addEventListener('submit', function(e) {
       e.preventDefault();
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
                        document.getElementById('username').textContent = formData.get('emailLogin');
                        document.getElementById('user-info').classList.remove('hidden');
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
        document.getElementById('logout-button').addEventListener('click', function() {
        let xhr = new XMLHttpRequest();
        xhr.open('GET', `${baseURL}/logout.sh`, true);
        xhr.onload = function() {
            if (xhr.status === 200) {
                alert("Sie wurden erfolgreich abgemeldet.");
                // UI zurücksetzen
                document.getElementById('user-info').classList.add('hidden');
                document.getElementById('map-group').classList.add('disabled');
                document.getElementById('ships-group').classList.add('disabled');

                document.getElementById('username').textContent ='';
                      for (let i = 1; i < groups.length; i++) {
                    groups[i].getElementsByClassName('content')[0].style.display = 'none';
                }
                groups[0].getElementsByClassName('content')[0].style.display = 'block';

            } else {
                alert("Fehler bei der Abmeldung: " + xhr.responseText);
            }
        };
        xhr.send();
    });


    let mapInitialized = false;
    function initializeMap() {
        const map = L.map('map').setView([53.54,8.5835], 17);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }).addTo(map);
        mapInitialized = true;
    }
};

/*
//Schiffe-Tabelle

    document.addEventListener('DOMContentLoaded', function() {
    const shipsContent = document.getElementById('ships-content');
    const shipsGroup = document.getElementById('ships-group');

    function fetchShipData() {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', '/docker-infra-2024-l-web/data.html', true);
        xhr.onload = function() {
            if (this.status === 200) {
                shipsContent.innerHTML = this.responseText;
            } else {
                console.error('Fehler beim Abrufen der Schiffsdaten:', this.statusText);
            }
        };
        xhr.onerror = function() {
            console.error('Anfrage fehlgeschlagen');
        };
        xhr.send();
    }

    //Schiffsdaten laden, wenn das Accordion geöffnet wird

    shipsGroup.getElementsByTagName('h3')[0].addEventListener('click', function() {
        const content = shipsGroup.getElementsByClassName('content')[0];
        if (content.style.display === 'block') {
            // Wenn Accordion geschlossen ist
        } else {
            // Accordion -öffnen, Daten abrufen
            fetchShipData();
            setInterval(fetchShipData, 3000); // Aktualisiere alle 3 Sekunden
        }
    });
});*/

