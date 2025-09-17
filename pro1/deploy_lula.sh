
#!/bin/bash
set -e  # Stop on error

echo "🚀 Starting Lula DB deployment..."

# Your socket
SOCKET="/data/data/com.termux/files/usr/var/run/mysqld.sock"

# Your password
PASSWORD="babsroot"

# Database name
DB="lula"

# Run SQL using MYSQL_PWD (safer for scripting)
MYSQL_PWD=$PASSWORD mariadb -u root --socket=$SOCKET $DB <<'EOF'

-- Drop procedure if it exists
DROP PROCEDURE IF EXISTS get_tasks_by_user;

DELIMITER //

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
END;
//

DELIMITER ;

EOF

echo "✅ Lula DB deployed successfully!"


