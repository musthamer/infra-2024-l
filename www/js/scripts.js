window.onload = function(){
  document.getElementById('register-form').addEventListener('submit', function(event){
    event.preventDefault();
    
    const formData = new FormData(this);
    const params = new URLSearchParams(); 
    
    for(const pair of formData.entries()){
      params.append(pair[0],pair[1]);
    }

    let xhr = new XMLHttpRequest(); 
    xhr.open('GET', '/docker-infra-2024-l-web/cgi-bin/Books_mangment/register.sh?'+ params.toString() , true );
    
    xhr.onload = function(){
      if(this.status === 200){
        alert("Registrierung Abgeschlossen ");
      }else{
        alert("Registrierung Fehlgeschlagen" + xhr.responseText);
      }
    }
    xhr.send();
  })
document.getElementById('login-form').addEventListener('submit', function(event){
    event.preventDefault();

    const formData = new FormData(this);
    const params = new URLSearchParams();

    for(const pair of formData.entries()){
        params.append(pair[0], pair[1]);
    }

    let xhr = new XMLHttpRequest();
    xhr.open('GET', '/docker-infra-2024-l-web/cgi-bin/Books_mangment/login.sh?' + params.toString(), true);

    xhr.onload = function() {
        if (xhr.status === 200) {
            const response = JSON.parse(this.responseText);
            if (response.status === "success") {
                window.location.href = "/docker-infra-2024-l-web/Books_mangment/"+response.redirect_url;
            } else {
                alert("Login Fehlgeschlagen: " + response.message);
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
} 

