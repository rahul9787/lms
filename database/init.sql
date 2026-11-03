CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'student'
);

CREATE TABLE IF NOT EXISTS events (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    venue VARCHAR(200),
    total_seats INTEGER NOT NULL,
    available_seats INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS registrations (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL,
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
    '2027-01-10',
    'Main Auditorium',
    100,
    100
),
(
    'Hackathon 2027',
    '24 hour coding hackathon',
    '2027-02-20',
    'Computer Lab',
    50,
    50
),
(
    'Cultural Fest',
    'Annual college cultural festival',
    '2027-03-05',
    'College Ground',
    500,
    500
);
