-- ✅ Lula Project Full Schema & Seed Data

USE lula;

DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    role ENUM('admin', 'manager', 'member') DEFAULT 'member',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    assigned_to INT,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status ENUM('pending', 'in_progress', 'completed') DEFAULT 'pending',
    priority ENUM('low', 'medium', 'high') DEFAULT 'medium',
    due_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_project_id ON tasks(project_id);
CREATE INDEX idx_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_status ON tasks(status);

INSERT INTO users (name, email, role) VALUES
('Alice', 'alice@example.com', 'admin'),
('Bob', 'bob@example.com', 'manager'),
('Charlie', 'charlie@example.com', 'member');

INSERT INTO projects (name, description, start_date, end_date) VALUES
('Lula Main Project', 'The main Lula initiative.', '2025-07-20', '2025-12-31');

INSERT INTO tasks (project_id, assigned_to, title, description, status, priority, due_date)
VALUES
(1, 1, 'Set up database', 'Design and deploy initial DB structure.', 'completed', 'high', '2025-07-20'),
(1, 2, 'Develop API', 'Build the backend API.', 'in_progress', 'high', '2025-08-15'),
(1, 3, 'Write documentation', 'Prepare project documentation.', 'pending', 'medium', '2025-08-31');

CREATE OR REPLACE VIEW active_tasks AS
SELECT
    t.id AS task_id,
    t.title,
    t.status,
    t.priority,
    t.due_date,
    p.name AS project_name,
    u.name AS assigned_user
FROM tasks t
JOIN projects p ON t.project_id = p.id
LEFT JOIN users u ON t.assigned_to = u.id
WHERE t.status != 'completed';

DELIMITER $$

CREATE PROCEDURE get_tasks_by_user(IN user_id INT)
BEGIN
    SELECT
        t.id,
        t.title,
        t.status,
        t.priority,
        t.due_date,
        p.name AS project_name
    FROM tasks t
    JOIN projects p ON t.project_id = p.id
    WHERE t.assigned_to = user_id;
END $$

DELIMITER ;
