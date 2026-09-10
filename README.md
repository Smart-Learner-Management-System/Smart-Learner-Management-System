# smart-learner-management-system 
Smart Learner Management System Database

PostgreSQL database for the Smart Learner Management System (SLMS). The database stores academic structure, student profiles, module enrolments, assessment results, tutoring requests, support requests, appointments, activities, achievements, and notifications.

The design follows relational database principles covered by the Microsoft DP-900 learning path. It uses primary keys, foreign keys, normalization, unique constraints, check constraints, indexes, views, stored procedures, functions, and triggers.

Scope

This database is intentionally focused on the student experience. It does not contain administrator, staff, role, authentication, audit-log, or staff-assignment tables. Authentication and authorization should be implemented by the application layer or identity provider.


Main database areas

Academic structure

The academic hierarchy is represented by Institution, Campus, Faculty, Qualification, Programme, Module, Subject, and Assessment. The hierarchy avoids repeating academic information in student and result records.

Student and progress

Student stores the learner profile. Enrolment resolves the many-to-many relationship between students and modules. Result stores assessment scores and grades. The database prevents duplicate enrolments for the same student, module, and academic year.

Student support

TutoringSession stores tutoring requests for enrolled modules. SupportCategory classifies support needs. SupportRequest stores student-submitted support cases. Appointment stores student appointment requests and may optionally link to a support request.

Engagement and communication

Activity and ActivityParticipation store extracurricular participation. Achievement stores student achievements linked optionally to an activity or module. Notification stores messages delivered to a student.

Requirements

•
PostgreSQL 14 or later; PostgreSQL 16 is recommended for local Docker development.

•
Docker Desktop, if using the container setup.

•
Git for source control.

•
A PostgreSQL client such as psql, pgAdmin, DBeaver, or DataGrip.

Quick start with Docker

Create a local project structure similar to the following:

Plain Text


project/
├── database/
│   └── SLMS_student_focused_schema_postgresql.sql
├── docker-compose.yml
└── .env



Create a .env file and keep it out of source control:

Plain Text


POSTGRES_DB=slms
POSTGRES_USER=slms_app
POSTGRES_PASSWORD=replace-with-a-local-password



Create docker-compose.yml:

YAML


services:
  postgres:
    image: postgres:16
    container_name: slms-postgres
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "5432:5432"
    volumes:
      - slms_data:/var/lib/postgresql/data
      - ./database:/docker-entrypoint-initdb.d

volumes:
  slms_data:



Start the database:

Bash


docker compose up -d



View the container logs:

Bash


docker compose logs -f postgres



Connect with psql:

Bash


psql "postgresql://slms_app:replace-with-a-local-password@localhost:5432/slms"



The SQL file in /docker-entrypoint-initdb.d runs automatically when the PostgreSQL volume is created for the first time. If the schema needs to be applied again to a fresh database, remove the local volume first:

Bash


docker compose down -v
docker compose up -d



Do not use down -v in a shared or production environment because it deletes the local database volume.

Manual installation

Create an empty database and run the schema with psql:

Bash


createdb slms
psql --set ON_ERROR_STOP=1 --dbname slms --file SLMS_student_focused_schema_postgresql.sql



The schema creates the tables, constraints, indexes, trigger, procedures, functions, and views inside a transaction for the table and index section. Run the script with a database account that has permission to create these objects.

Stored procedures

The procedures centralize common application operations.

Procedure
Purpose
sp_enrol_student(student_id, module_id, academic_year)
Creates or reactivates a student enrolment.
sp_record_result(enrolment_id, assessment_id, score, grade)
Inserts or updates a result and derives a grade when needed.
sp_request_tutoring(student_id, module_id, requested_date, student_note)
Creates a tutoring request for an actively enrolled module.
sp_create_support_request(student_id, category_id, subject, description, consent_given)
Creates a student support request.
sp_mark_notification_read(student_id, notification_id)
Marks one of the student’s notifications as read.




Procedure examples

SQL


CALL sp_enrol_student(1, 10, 2026);

CALL sp_record_result(1, 20, 78.50, NULL);

CALL sp_request_tutoring(
    1,
    10,
    '2026-09-15 10:00:00+02',
    'Please help me understand database joins'
);

CALL sp_create_support_request(
    1,
    2,
    'Academic support',
    'Please assist with my module plan',
    TRUE
);

CALL sp_mark_notification_read(1, 5);



Functions and views

fn_student_module_mark(enrolment_id) calculates the weighted mark for one module enrolment.

fn_student_progress(student_id) returns the student’s module progress, academic year, enrolment status, and weighted mark.

vw_student_progress provides a dashboard-ready view of student module progress.

vw_student_assessment_results provides a dashboard-ready view of student assessment results.

Example queries:

SQL


SELECT fn_student_module_mark(1);

SELECT *
FROM fn_student_progress(1);

SELECT *
FROM vw_student_progress
WHERE StudentID = 1;

SELECT *
FROM vw_student_assessment_results
WHERE StudentID = 1
ORDER BY RecordedDate DESC;



Validation logic

The TR_Result_ValidateModule trigger runs before a result is inserted or updated. It checks that the assessment belongs to the same module as the student enrolment. This prevents a result from being attached to the wrong module.

The schema also validates:

•
Assessment weights between 0 and 100.

•
Scores between 0 and 100.

•
Positive module credits.

•
Valid enrolment and request statuses.

•
Valid achievement visibility levels.

•
Valid date ranges.

•
Unique student email addresses, student numbers, module codes, and assessment titles within their relevant scope.

Recommended application architecture

Use a three-layer arrangement:

1.
Frontend: Vercel or another frontend host for the student interface.

2.
API: Render, Azure, or another backend host for application logic and database access.

3.
Database: PostgreSQL locally through Docker and Azure Database for PostgreSQL or another managed PostgreSQL service for production.

The frontend should call the API. The API should call the stored procedures, functions, and views. The frontend should not connect directly to PostgreSQL.

Security practices

•
Never commit .env files or database passwords to GitHub.

•
Use separate database accounts for development, testing, and production.

•
Give the API account only the permissions it requires.

•
Use TLS for remote PostgreSQL connections.

•
Restrict production database network access.

•
Enable backups before using the database with real student information.

•
Do not store passwords in the Student table.

•
Do not use real student personal information in development seed data.

•
Review privacy and data-protection requirements before deployment.

Team workflow

Use Git branches for changes:

Bash


git checkout -b feature/database-change
git add database/
git commit -m "Add database change"
git push -u origin feature/database-change



Team members should review SQL changes before merging. Schema changes should be backward-compatible where possible. For future work, place incremental changes in numbered migration files, for example:

Plain Text


 database/
 ├── 001_initial_schema.sql
 ├── 002_add_student_preferences.sql
 └── 003_add_learning_events.sql



Diagrams

The project includes an ERD, UML class diagram, and editable Drawio use-case diagram. Open SLMS_use_case_diagram.drawio with diagrams.net to edit the use-case model.

References

•
Microsoft Learn DP-900 study guide

•
PostgreSQL CREATE PROCEDURE documentation

•
PostgreSQL CREATE FUNCTION documentation



## Day 3 - Run a local containerized database - DONE

**Task:** Run PostgreSQL using Docker Official Image from Docker Hub.

**What I did:**
- Created `docker-compose.yml` with postgres:15 image
- PostgreSQL, MySQL, MongoDB all have Docker Official Images on Docker Hub that follow best practices.
- Configured container: user=postgres, password=postgres, db=smart_learner, port 5432

**Issue encountered:**
Docker Desktop failed to start - "Virtualization support not detected" (screenshot attached). Virtualization is disabled in BIOS on this device.

**Solution / Proof:**
Successfully ran containerized database using Play-with-Docker cloud (labs.play-with-docker.com) as alternative environment:
- Command: `docker compose up -d` 
- Verified with `docker ps` - smart_learner_db running
- Imported schema: `SLMS_student_focused_schema_postgresql.sql`

This proves understanding of containerized database concept despite local hardware limitation.

•
Docker Compose documentation




