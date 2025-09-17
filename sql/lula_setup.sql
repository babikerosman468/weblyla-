CREATE DATABASE IF NOT EXISTS lula_support;
USE lula_support;

CREATE TABLE groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
) ENGINE=InnoDB;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150),
    phone VARCHAR(50),
    role ENUM('student', 'helper') NOT NULL,
    group_id INT,
    FOREIGN KEY (group_id) REFERENCES groups(id)
) ENGINE=InnoDB;

CREATE TABLE activities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    scheduled_at DATETIME,
    FOREIGN KEY (group_id) REFERENCES groups(id)
) ENGINE=InnoDB;

