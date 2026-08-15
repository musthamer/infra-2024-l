CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    firstname VARCHAR(255) NOT NULL,
    lastname VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sessions (
    session_id VARCHAR(64) NOT NULL PRIMARY KEY,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ships (
    mmsi VARCHAR(255) NOT NULL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    ship_name VARCHAR(255)
);


CREATE TABLE IF NOT EXISTS positions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ship_mmsi VARCHAR(255) NOT NULL,
    latitude DECIMAL(9,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ship_mmsi) REFERENCES ships(mmsi) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS email_jobs (
    job_id VARCHAR(64) NOT NULL PRIMARY KEY,
    job_type VARCHAR(32) NOT NULL,
    payload TEXT NOT NULL,
    status ENUM('pending', 'processing', 'completed', 'failed') NOT NULL DEFAULT 'pending',
    worker_id VARCHAR(64) NULL,
    error_message VARCHAR(255) NULL,
    attempts INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP NULL DEFAULT NULL,
    finished_at TIMESTAMP NULL DEFAULT NULL
);

ALTER TABLE sessions ADD INDEX IF NOT EXISTS idx_sessions_user_id (user_id);
ALTER TABLE sessions ADD INDEX IF NOT EXISTS idx_sessions_created_at (created_at);

ALTER TABLE positions ADD INDEX IF NOT EXISTS idx_positions_ship_ts (ship_mmsi, timestamp);
ALTER TABLE positions ADD INDEX IF NOT EXISTS idx_positions_ts (timestamp);

ALTER TABLE email_jobs ADD INDEX IF NOT EXISTS idx_email_jobs_status_created (status, created_at);
ALTER TABLE email_jobs ADD INDEX IF NOT EXISTS idx_email_jobs_status_worker (status, worker_id, started_at);

