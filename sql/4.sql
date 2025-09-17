INSERT INTO contacts (name, email, message)
VALUES
('Alice Johnson', 'alice@example.com', 'Hello from Alice!'),
('Bob Smith', 'bob@example.com', 'Interested in your services.'),
('Carol Lee', 'carol@example.com', 'Please call me back.'),
('David Kim', 'david@example.com', 'Thanks for the info.'),
('Eva Green', 'eva@example.com', 'Looking forward to meeting.'),
('Frank White', 'frank@example.com', 'Can you send details?'),
('Grace Liu', 'grace@example.com', 'Inquiry about pricing.'),
('Henry Adams', 'henry@example.com', 'Feedback on your website.'),
('Isabel Clark', 'isabel@example.com', 'Requesting a demo.'),
('Jack Miller', 'jack@example.com', 'Happy to connect!');




SELECT * FROM contacts LIMIT 10;

Once inserted, run your send.py script on Termux to send these 10 contacts to your laptop server — it will send the fresh test data!



