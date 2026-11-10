-- LMS Database Initialization

-- Users table for authentication
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'STUDENT'
        CHECK (role IN ('STUDENT', 'TRAINER')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Courses table
CREATE TABLE IF NOT EXISTS courses (
    id SERIAL PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(100),
    description TEXT,
    level VARCHAR(30) DEFAULT 'Beginner',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample courses
INSERT INTO courses (title, category, description, level)
VALUES
('AWS Cloud Fundamentals', 'Cloud Computing', 'Learn AWS services, IAM, EC2 and cloud storage.', 'Beginner'),
('Python Programming', 'Programming', 'Learn Python syntax, functions and programming fundamentals.', 'Beginner'),
('Docker and DevOps', 'Engineering', 'Learn Docker, containers, Compose and CI/CD.', 'Intermediate'),
('Java and Spring Boot', 'Backend Development', 'Learn Java and build REST APIs using Spring Boot.', 'Intermediate'),
('Data Analytics', 'Analytics', 'Learn data preparation, analysis and visualization.', 'Beginner'),
('HTML CSS and JavaScript', 'Web Development', 'Build responsive and interactive websites.', 'Beginner');
