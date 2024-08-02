CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    firstname VARCHAR(255) NOT NULL,
    lastname VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sessions (
    session_id VARCHAR(64) NOT NULL PRIMARY KEY,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ships (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    ship_id INT NOT NULL,
    mmsi VARCHAR(255) NOT NULL,
    status1 VARCHAR(255),
    status2 VARCHAR(255),
    status3 VARCHAR(255),
    status4 VARCHAR(255),
    lon DECIMAL(9,6),
    lat DECIMAL(9,6),
    course DECIMAL(5,1),
    speed DECIMAL(5,1),
    status5 VARCHAR(255),
    status6 VARCHAR(255),
    status7 VARCHAR(255),
    status8 VARCHAR(255),
    status9 VARCHAR(255),
    status10 VARCHAR(255)
);

-- Beispiel-Schiffsdaten hinzufügen
INSERT INTO ships (timestamp, ship_id, mmsi, status1, status2, status3, status4, lon, lat, course, speed, status5, status6, status7, status9, status10)
VALUES ('2024-07-18 23:26:07', 1, '211537690', 'Under way using engine', 'undefined', '0', 'false', 8.5774, 53.5364, 231.2, 225, '7', '0', 'Not available', 'false', '27240');

CREATE TABLE positions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ship_id INT NOT NULL,
    latitude DECIMAL(9,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ship_id) REFERENCES ships(id) ON DELETE CASCADE
);

