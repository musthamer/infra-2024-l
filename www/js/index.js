const baseURL = '/docker-infra-2024-l-web/cgi-bin/Books_mangment/';
document.getElementById('registerForm').addEventListener('submit', function(e) {
    e.preventDefault();
    const formData = new FormData(e.target);
    formData.append('action', 'register');
    const params = new URLSearchParams(formData).toString();

    const xhr = new XMLHttpRequest();
    xhr.open('GET', baseURL + 'register.sh?' + params, true);

    xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
            if (xhr.status === 200) {
                const responseText = xhr.responseText;
                try {
                    const data = JSON.parse(responseText);
                    alert(data.message);
                } catch (error) {
                    console.error('Error parsing JSON:', error);
                    alert('Registration failed. Please check the console for more details.');
                }
            } else {
                console.error('Error:', xhr.statusText);
                alert('Registration failed. Please check the console for more details.');
            }
        }
    };

    xhr.send();
});

