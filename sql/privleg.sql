GRANT ALL PRIVILEGES ON lula.* TO 'babsuser'@'localhost';

FLUSH PRIVILEGES;




You granted:

GRANT ALL PRIVILEGES ON lula.* TO 'babsuser'@'localhost';

But the error says:

INSERT command denied to user 'babsuser'@'localhost' for table `Lula`.`contacts`

See the difference? → Lula vs lula


---

✅ Fix it

Run this to be safe:

GRANT ALL PRIVILEGES ON `Lula`.* TO 'babsuser'@'localhost';

FLUSH PRIVILEGES;

MariaDB will then see both lula and Lula.


---

🔑 Then test again

1️⃣ ./manage3.sh stop_lula
2️⃣ ./manage3.sh start_lula
3️⃣ Submit a new contact form → watch it insert!


---
:
If needed, run:

SHOW GRANTS FOR 'babsuser'@'localhost';



