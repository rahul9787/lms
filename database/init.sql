CREATE DATABASE IF NOT EXISTS college_event_db;

USE college_event_db;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'student'
);

CREATE TABLE events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    venue VARCHAR(200),
    total_seats INT NOT NULL,
    available_seats INT NOT NULL
);

CREATE TABLE registrations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    student_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    college VARCHAR(200),
    department VARCHAR(100),
    phone VARCHAR(20),
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (event_id) REFERENCES events(id)
);

INSERT INTO events
(title, description, event_date, venue, total_seats, available_seats)
VALUES
(
    'Technical Symposium',
    'College technical symposium',
    '2026-09-10',
    'Main Auditorium',
    100,
    100
),
(
    'Hackathon 2026',
    '24 hour coding hackathon',
    '2026-09-20',
    'Computer Lab',
    50,
    50
),
(
    'Cultural Fest',
    'Annual college cultural festival',
    '2026-10-05',
    'College Ground',
    500,
    500
);