libname lula '/folders/myfolders/lula';

data lula.activities;
    do id = 1 to 4;
        group_id = ceil(ranuni(1234) * 5);
        if id = 1 then title = "Study Group";
        else if id = 2 then title = "Mentoring Session";
        else if id = 3 then title = "Workshop";
        else title = "Peer Tutoring";
        description = catt("Description for ", title);
        scheduled_at = datetime() + id*86400; /* each next day */
        output;
    end;
    format scheduled_at datetime20.;
run;

/* 3️⃣ Create users dataset (100 students) */
data lula.users;
    do id = 1 to 100;
        name = catt("Student_", put(id, 3. -L));
        email = catt("student", id, "@example.com");
        phone = catt("+2499000", put(1000+id, z4.));
        role = "student";
        group_id = ceil(ranuni(1234) * 5);
        output;
    end;
run;

/* 4️⃣ Create participation dataset (simulate engagement) */
data lula.participation;
    do i = 1 to 200;
        user_id = ceil(ranuni(1234) * 100);
        activity_id = ceil(ranuni(1234) * 4);
        engagement_score = ceil(ranuni(1234) * 10);
        output;
    end;
    drop i;
run;

/* 5️⃣ Print sample records */
proc print data=lula.activities (obs=10);
    title 'Sample Activities';
run;

proc print data=lula.users (obs=10);
    title 'Sample Users';
run;

proc print data=lula.participation (obs=10);
    title 'Sample Participation Records';
run;

/* 6️⃣ Summary statistics */
proc means data=lula.participation mean n;
    class activity_id;
    var engagement_score;
    title 'Engagement Score Summary by Activity';
run;

/* 7️⃣ Export results to CSV files */
proc export data=lula.activities
    outfile="/folders/myfolders/lula/activities.csv"
    dbms=csv replace;
run;

proc export data=lula.users
    outfile="/folders/myfolders/lula/users.csv"
    dbms=csv replace;
run;

proc export data=lula.participation
    outfile="/folders/myfolders/lula/participation.csv"
    dbms=csv replace;
run;


