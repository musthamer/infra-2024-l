const baseURL = '/docker-infra-2024-l-web/cgi-bin/Books_mangment/';

document.getElementById('registerForm').addEventListener('submit', handleFormSubmit);
document.getElementById('loginForm').addEventListener('submit', handleFormSubmit);
document.getElementById('testForm').addEventListener('submit', testCall); 

function testCall(e){
  e.preventDefault();
  const form = e.target;
  
}
function handleFormSubmit(e) {
    e.preventDefault();
    const form = e.target;
    const params = new URLSearchParams();

    // Iteriere über die Formulardaten und füge sie zu den URL-Parametern hinzu
    for (let i = 0; i < form.elements.length; i++) {
        const element = form.elements[i];
        if (element.name) {
            params.append(element.name, element.value);
        }
    }

    // Bestimme die Aktion basierend auf dem Formular-ID
    if (form.id === 'registerForm') {
        params.append('action', 'register');
    } else if (form.id === 'loginForm') {
        params.append('action', 'login');
    }

    const xhr = new XMLHttpRequest();
    xhr.open('GET', baseURL + (form.id === 'registerForm' ? 'register.sh?' : 'login.sh?') + params.toString(), true);

    xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
            if (xhr.status === 200) {
                const responseText = xhr.responseText.trim();
                console.log('Response Text:', responseText);

                if (responseText) {
                    try {
                        const data = JSON.parse(responseText);
                        console.log(data);
                        alert(data.message + (form.id === 'registerForm' ? data.status : ''));
                    } catch (error) {
                        console.error('Error parsing JSON:', error);
                        alert((form.id === 'registerForm' ? 'Registration' : 'Anmeldung') + ' failed. Please check the console for more details.');
                    }
                } else {
                    console.error('Error: Empty response from server');
                    alert((form.id === 'registerForm' ? 'Registration' : 'Anmeldung') + ' failed. Server returned an empty response.');
                }
            } else {
                console.error('Error:', xhr.statusText);
                alert((form.id === 'registerForm' ? 'Registration' : 'Anmeldung') + ' failed. Please check the console for more details.');
            }
        }
    };

    xhr.send();
}

