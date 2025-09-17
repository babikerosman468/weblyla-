INSERT INTO groups (name, description)
VALUES ('Medical Helpers', 'Group helping stressed students cope with trauma');

INSERT INTO users (name, email, phone, role, group_id)
VALUES ('Lula', 'lula@example.com', '123456789', 'helper', 1);

INSERT INTO activities (group_id, title, description, scheduled_at)
VALUES (1, 'Trauma Workshop', 'Online session to discuss stress relief techniques', NOW());

