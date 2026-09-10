
BEGIN;

-- =====================================================================
-- 1. ACADEMIC STRUCTURE
-- =====================================================================

CREATE TABLE Institution (
    InstitutionID   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Name            VARCHAR(150) NOT NULL,
    Country         VARCHAR(80) NOT NULL DEFAULT 'South Africa',
    InstitutionType VARCHAR(50) NOT NULL,
    CreatedDate     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT UQ_Institution_Name UNIQUE (Name)
);

CREATE TABLE Campus (
    CampusID        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    InstitutionID   INTEGER NOT NULL,
    Name            VARCHAR(120) NOT NULL,
    City            VARCHAR(100),
    IsResidential   BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT FK_Campus_Institution FOREIGN KEY (InstitutionID)
        REFERENCES Institution(InstitutionID) ON DELETE CASCADE,
    CONSTRAINT UQ_Campus_Name UNIQUE (InstitutionID, Name)
);

CREATE TABLE Faculty (
    FacultyID       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CampusID        INTEGER NOT NULL,
    Name            VARCHAR(150) NOT NULL,
    CONSTRAINT FK_Faculty_Campus FOREIGN KEY (CampusID)
        REFERENCES Campus(CampusID) ON DELETE CASCADE,
    CONSTRAINT UQ_Faculty_Name UNIQUE (CampusID, Name)
);

CREATE TABLE Qualification (
    QualificationID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    FacultyID       INTEGER NOT NULL,
    Name            VARCHAR(150) NOT NULL,
    NQFLevel        SMALLINT,
    TotalCredits    SMALLINT,
    CONSTRAINT FK_Qualification_Faculty FOREIGN KEY (FacultyID)
        REFERENCES Faculty(FacultyID) ON DELETE CASCADE,
    CONSTRAINT CK_Qualification_NQFLevel CHECK (NQFLevel IS NULL OR NQFLevel BETWEEN 1 AND 10),
    CONSTRAINT CK_Qualification_Credits CHECK (TotalCredits IS NULL OR TotalCredits > 0),
    CONSTRAINT UQ_Qualification_Name UNIQUE (FacultyID, Name)
);

CREATE TABLE Programme (
    ProgrammeID     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    QualificationID INTEGER NOT NULL,
    Name            VARCHAR(150) NOT NULL,
    DurationYears   SMALLINT NOT NULL DEFAULT 3,
    CONSTRAINT FK_Programme_Qualification FOREIGN KEY (QualificationID)
        REFERENCES Qualification(QualificationID) ON DELETE CASCADE,
    CONSTRAINT CK_Programme_Duration CHECK (DurationYears BETWEEN 1 AND 10),
    CONSTRAINT UQ_Programme_Name UNIQUE (QualificationID, Name)
);

CREATE TABLE Module (
    ModuleID             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ProgrammeID          INTEGER NOT NULL,
    ModuleCode           VARCHAR(20) NOT NULL,
    Name                 VARCHAR(150) NOT NULL,
    Credits              SMALLINT NOT NULL,
    Semester             SMALLINT,
    PrerequisiteModuleID INTEGER,
    CONSTRAINT FK_Module_Programme FOREIGN KEY (ProgrammeID)
        REFERENCES Programme(ProgrammeID) ON DELETE CASCADE,
    CONSTRAINT FK_Module_Prerequisite FOREIGN KEY (PrerequisiteModuleID)
        REFERENCES Module(ModuleID) ON DELETE SET NULL,
    CONSTRAINT CK_Module_Credits CHECK (Credits > 0),
    CONSTRAINT CK_Module_Semester CHECK (Semester IS NULL OR Semester BETWEEN 1 AND 3),
    CONSTRAINT CK_Module_NoSelfPrerequisite CHECK (PrerequisiteModuleID IS NULL OR PrerequisiteModuleID <> ModuleID),
    CONSTRAINT UQ_Module_Code UNIQUE (ProgrammeID, ModuleCode)
);

CREATE TABLE Subject (
    SubjectID       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ModuleID        INTEGER NOT NULL,
    Name            VARCHAR(150) NOT NULL,
    LearningOutcome VARCHAR(500),
    CONSTRAINT FK_Subject_Module FOREIGN KEY (ModuleID)
        REFERENCES Module(ModuleID) ON DELETE CASCADE,
    CONSTRAINT UQ_Subject_Name UNIQUE (ModuleID, Name)
);

CREATE TABLE Assessment (
    AssessmentID    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ModuleID        INTEGER NOT NULL,
    Title           VARCHAR(150) NOT NULL,
    AssessmentType  VARCHAR(50) NOT NULL,
    WeightPercent   NUMERIC(5,2) NOT NULL,
    DueDate         DATE,
    CONSTRAINT FK_Assessment_Module FOREIGN KEY (ModuleID)
        REFERENCES Module(ModuleID) ON DELETE CASCADE,
    CONSTRAINT CK_Assessment_Weight CHECK (WeightPercent BETWEEN 0 AND 100),
    CONSTRAINT UQ_Assessment_Title UNIQUE (ModuleID, Title)
);

-- =====================================================================
-- 2. STUDENT PROFILE
-- =====================================================================

CREATE TABLE Student (
    StudentID          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    InstitutionID      INTEGER NOT NULL,
    QualificationID    INTEGER NOT NULL,
    FirstName          VARCHAR(80) NOT NULL,
    LastName           VARCHAR(80) NOT NULL,
    StudentNumber      VARCHAR(40) NOT NULL,
    Email              VARCHAR(150) NOT NULL,
    PreferredLanguage  VARCHAR(40),
    EnrolmentYear      SMALLINT NOT NULL,
    Status             VARCHAR(30) NOT NULL DEFAULT 'Active',
    CreatedDate        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Student_Institution FOREIGN KEY (InstitutionID)
        REFERENCES Institution(InstitutionID),
    CONSTRAINT FK_Student_Qualification FOREIGN KEY (QualificationID)
        REFERENCES Qualification(QualificationID),
    CONSTRAINT CK_Student_Status CHECK (Status IN ('Active', 'Inactive', 'Graduated', 'Suspended')),
    CONSTRAINT CK_Student_EnrolmentYear CHECK (EnrolmentYear BETWEEN 2000 AND 2100),
    CONSTRAINT UQ_Student_Number UNIQUE (InstitutionID, StudentNumber),
    CONSTRAINT UQ_Student_Email UNIQUE (Email)
);

-- =====================================================================
-- 3. ENROLMENT, RESULTS, AND PROGRESS
-- =====================================================================

CREATE TABLE Enrolment (
    EnrolmentID     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    StudentID       INTEGER NOT NULL,
    ModuleID        INTEGER NOT NULL,
    AcademicYear    SMALLINT NOT NULL,
    Status          VARCHAR(30) NOT NULL DEFAULT 'Enrolled',
    EnrolledDate    DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT FK_Enrolment_Student FOREIGN KEY (StudentID)
        REFERENCES Student(StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_Enrolment_Module FOREIGN KEY (ModuleID)
        REFERENCES Module(ModuleID),
    CONSTRAINT CK_Enrolment_Status CHECK (Status IN ('Enrolled', 'Completed', 'Repeat', 'Withdrawn')),
    CONSTRAINT CK_Enrolment_AcademicYear CHECK (AcademicYear BETWEEN 2000 AND 2100),
    CONSTRAINT UQ_Enrolment UNIQUE (StudentID, ModuleID, AcademicYear)
);

CREATE TABLE Result (
    ResultID        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    EnrolmentID     INTEGER NOT NULL,
    AssessmentID    INTEGER NOT NULL,
    Score           NUMERIC(5,2),
    Grade           VARCHAR(5),
    RecordedDate    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Result_Enrolment FOREIGN KEY (EnrolmentID)
        REFERENCES Enrolment(EnrolmentID) ON DELETE CASCADE,
    CONSTRAINT FK_Result_Assessment FOREIGN KEY (AssessmentID)
        REFERENCES Assessment(AssessmentID),
    CONSTRAINT CK_Result_Score CHECK (Score IS NULL OR Score BETWEEN 0 AND 100),
    CONSTRAINT UQ_Result_Assessment UNIQUE (EnrolmentID, AssessmentID)
);

-- =====================================================================
-- 4. STUDENT-INITIATED ACADEMIC SUPPORT
-- =====================================================================

CREATE TABLE TutoringSession (
    SessionID       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    StudentID       INTEGER NOT NULL,
    ModuleID        INTEGER NOT NULL,
    RequestedDate   TIMESTAMPTZ,
    SessionDate     TIMESTAMPTZ,
    Status          VARCHAR(30) NOT NULL DEFAULT 'Requested',
    StudentNote     VARCHAR(1000),
    Outcome         VARCHAR(500),
    CreatedDate     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Tutoring_Student FOREIGN KEY (StudentID)
        REFERENCES Student(StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_Tutoring_Module FOREIGN KEY (ModuleID)
        REFERENCES Module(ModuleID),
    CONSTRAINT CK_Tutoring_Status CHECK (Status IN ('Requested', 'Scheduled', 'Completed', 'Cancelled')),
    CONSTRAINT CK_Tutoring_Dates CHECK (SessionDate IS NULL OR RequestedDate IS NULL OR SessionDate >= RequestedDate)
);

CREATE TABLE SupportCategory (
    CategoryID      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Name            VARCHAR(80) NOT NULL,
    IsRestricted    BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT UQ_SupportCategory_Name UNIQUE (Name)
);

CREATE TABLE SupportRequest (
    SupportRequestID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    StudentID        INTEGER NOT NULL,
    CategoryID       INTEGER NOT NULL,
    Subject          VARCHAR(150) NOT NULL,
    Description      VARCHAR(2000) NOT NULL,
    ConsentGiven     BOOLEAN NOT NULL DEFAULT FALSE,
    Status           VARCHAR(30) NOT NULL DEFAULT 'Open',
    CreatedDate      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ClosedDate       TIMESTAMPTZ,
    CONSTRAINT FK_SupportRequest_Student FOREIGN KEY (StudentID)
        REFERENCES Student(StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_SupportRequest_Category FOREIGN KEY (CategoryID)
        REFERENCES SupportCategory(CategoryID),
    CONSTRAINT CK_SupportRequest_Status CHECK (Status IN ('Open', 'InProgress', 'Resolved', 'Closed', 'Cancelled')),
    CONSTRAINT CK_SupportRequest_ClosedDate CHECK (ClosedDate IS NULL OR ClosedDate >= CreatedDate)
);

CREATE TABLE Appointment (
    AppointmentID   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    StudentID       INTEGER NOT NULL,
    SupportRequestID INTEGER,
    ServiceType     VARCHAR(60) NOT NULL,
    RequestedDate   TIMESTAMPTZ NOT NULL,
    ScheduledDate   TIMESTAMPTZ,
    Status          VARCHAR(30) NOT NULL DEFAULT 'Requested',
    StudentNote     VARCHAR(1000),
    Outcome         VARCHAR(500),
    CreatedDate     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Appointment_Student FOREIGN KEY (StudentID)
        REFERENCES Student(StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_Appointment_Request FOREIGN KEY (SupportRequestID)
        REFERENCES SupportRequest(SupportRequestID) ON DELETE SET NULL,
    CONSTRAINT CK_Appointment_Status CHECK (Status IN ('Requested', 'Scheduled', 'Completed', 'Cancelled')),
    CONSTRAINT CK_Appointment_Dates CHECK (ScheduledDate IS NULL OR ScheduledDate >= RequestedDate)
);

-- =====================================================================
-- 5. ACTIVITIES AND STUDENT ACHIEVEMENTS
-- =====================================================================

CREATE TABLE Activity (
    ActivityID      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    InstitutionID   INTEGER NOT NULL,
    ActivityType    VARCHAR(40) NOT NULL,
    Name            VARCHAR(150) NOT NULL,
    Description     VARCHAR(500),
    CONSTRAINT FK_Activity_Institution FOREIGN KEY (InstitutionID)
        REFERENCES Institution(InstitutionID) ON DELETE CASCADE,
    CONSTRAINT UQ_Activity_Name UNIQUE (InstitutionID, Name)
);

CREATE TABLE ActivityParticipation (
    ParticipationID  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    StudentID        INTEGER NOT NULL,
    ActivityID       INTEGER NOT NULL,
    RoleInActivity   VARCHAR(60),
    StartDate        DATE NOT NULL,
    EndDate          DATE,
    CONSTRAINT FK_Participation_Student FOREIGN KEY (StudentID)
        REFERENCES Student(StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_Participation_Activity FOREIGN KEY (ActivityID)
        REFERENCES Activity(ActivityID) ON DELETE CASCADE,
    CONSTRAINT CK_Participation_Dates CHECK (EndDate IS NULL OR EndDate >= StartDate),
    CONSTRAINT UQ_ActivityParticipation UNIQUE (StudentID, ActivityID, StartDate)
);

CREATE TABLE Achievement (
    AchievementID    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    StudentID        INTEGER NOT NULL,
    ActivityID       INTEGER,
    ModuleID         INTEGER,
    AchievementType  VARCHAR(60) NOT NULL,
    Description      VARCHAR(300) NOT NULL,
    VisibilityLevel  VARCHAR(20) NOT NULL DEFAULT 'Private',
    DateAwarded      DATE NOT NULL,
    CONSTRAINT FK_Achievement_Student FOREIGN KEY (StudentID)
        REFERENCES Student(StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_Achievement_Activity FOREIGN KEY (ActivityID)
        REFERENCES Activity(ActivityID) ON DELETE SET NULL,
    CONSTRAINT FK_Achievement_Module FOREIGN KEY (ModuleID)
        REFERENCES Module(ModuleID) ON DELETE SET NULL,
    CONSTRAINT CK_Achievement_Visibility CHECK (VisibilityLevel IN ('Private', 'Portfolio', 'Public'))
);

-- =====================================================================
-- 6. STUDENT NOTIFICATIONS
-- =====================================================================

CREATE TABLE Notification (
    NotificationID INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    StudentID      INTEGER NOT NULL,
    Purpose        VARCHAR(150) NOT NULL,
    Channel        VARCHAR(30) NOT NULL DEFAULT 'InApp',
    Status         VARCHAR(20) NOT NULL DEFAULT 'Unread',
    Message        VARCHAR(1000) NOT NULL,
    CreatedDate    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ReadDate       TIMESTAMPTZ,
    CONSTRAINT FK_Notification_Student FOREIGN KEY (StudentID)
        REFERENCES Student(StudentID) ON DELETE CASCADE,
    CONSTRAINT CK_Notification_Channel CHECK (Channel IN ('InApp', 'Email', 'SMS')),
    CONSTRAINT CK_Notification_Status CHECK (Status IN ('Unread', 'Read', 'Archived')),
    CONSTRAINT CK_Notification_ReadDate CHECK (ReadDate IS NULL OR Status IN ('Read', 'Archived'))
);

-- =====================================================================
-- 7. INDEXES FOR STUDENT DASHBOARDS AND COMMON LOOKUPS
-- =====================================================================

CREATE INDEX IX_Student_Qualification ON Student(QualificationID);
CREATE UNIQUE INDEX UX_Student_Email_CaseInsensitive ON Student(LOWER(Email));
CREATE INDEX IX_Enrolment_Student ON Enrolment(StudentID);
CREATE INDEX IX_Enrolment_Student_Status ON Enrolment(StudentID, Status);
CREATE INDEX IX_Result_Enrolment ON Result(EnrolmentID);
CREATE INDEX IX_Assessment_Module_DueDate ON Assessment(ModuleID, DueDate);
CREATE INDEX IX_Tutoring_Student_Status ON TutoringSession(StudentID, Status);
CREATE INDEX IX_SupportRequest_Student_Status ON SupportRequest(StudentID, Status);
CREATE INDEX IX_Appointment_Student_Status ON Appointment(StudentID, Status);
CREATE INDEX IX_ActivityParticipation_Student ON ActivityParticipation(StudentID);
CREATE INDEX IX_Achievement_Student ON Achievement(StudentID);
CREATE INDEX IX_Notification_Student_Status ON Notification(StudentID, Status, CreatedDate DESC);

COMMIT;

-- =====================================================================
-- 8. REUSABLE DATABASE LOGIC
-- =====================================================================

CREATE OR REPLACE FUNCTION fn_validate_result_module()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    enrolled_module_id INTEGER;
    assessment_module_id INTEGER;
BEGIN
    SELECT ModuleID
      INTO enrolled_module_id
      FROM Enrolment
     WHERE EnrolmentID = NEW.EnrolmentID;

    SELECT ModuleID
      INTO assessment_module_id
      FROM Assessment
     WHERE AssessmentID = NEW.AssessmentID;

    IF enrolled_module_id IS NULL THEN
        RAISE EXCEPTION 'Enrolment % does not exist', NEW.EnrolmentID;
    END IF;

    IF assessment_module_id IS NULL THEN
        RAISE EXCEPTION 'Assessment % does not exist', NEW.AssessmentID;
    END IF;

    IF enrolled_module_id <> assessment_module_id THEN
        RAISE EXCEPTION
            'Assessment % belongs to module %, but enrolment % belongs to module %',
            NEW.AssessmentID, assessment_module_id, NEW.EnrolmentID, enrolled_module_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER TR_Result_ValidateModule
BEFORE INSERT OR UPDATE OF EnrolmentID, AssessmentID ON Result
FOR EACH ROW
EXECUTE FUNCTION fn_validate_result_module();

CREATE OR REPLACE PROCEDURE sp_enrol_student(
    IN p_student_id INTEGER,
    IN p_module_id INTEGER,
    IN p_academic_year SMALLINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Student WHERE StudentID = p_student_id) THEN
        RAISE EXCEPTION 'Student % does not exist', p_student_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Module WHERE ModuleID = p_module_id) THEN
        RAISE EXCEPTION 'Module % does not exist', p_module_id;
    END IF;

    INSERT INTO Enrolment (StudentID, ModuleID, AcademicYear, Status)
    VALUES (p_student_id, p_module_id, p_academic_year, 'Enrolled')
    ON CONFLICT (StudentID, ModuleID, AcademicYear)
    DO UPDATE SET Status = 'Enrolled';
END;
$$;

CREATE OR REPLACE PROCEDURE sp_record_result(
    IN p_enrolment_id INTEGER,
    IN p_assessment_id INTEGER,
    IN p_score NUMERIC(5,2),
    IN p_grade VARCHAR(5) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    calculated_grade VARCHAR(5);
BEGIN
    IF p_score IS NULL OR p_score < 0 OR p_score > 100 THEN
        RAISE EXCEPTION 'Score must be between 0 and 100';
    END IF;

    calculated_grade := COALESCE(
        p_grade,
        CASE
            WHEN p_score >= 75 THEN 'A'
            WHEN p_score >= 60 THEN 'B'
            WHEN p_score >= 50 THEN 'C'
            WHEN p_score >= 40 THEN 'D'
            ELSE 'F'
        END
    );

    INSERT INTO Result (EnrolmentID, AssessmentID, Score, Grade)
    VALUES (p_enrolment_id, p_assessment_id, p_score, calculated_grade)
    ON CONFLICT (EnrolmentID, AssessmentID)
    DO UPDATE SET
        Score = EXCLUDED.Score,
        Grade = EXCLUDED.Grade,
        RecordedDate = CURRENT_TIMESTAMP;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_request_tutoring(
    IN p_student_id INTEGER,
    IN p_module_id INTEGER,
    IN p_requested_date TIMESTAMPTZ,
    IN p_student_note VARCHAR(1000) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM Enrolment
         WHERE StudentID = p_student_id
           AND ModuleID = p_module_id
           AND Status IN ('Enrolled', 'Repeat')
    ) THEN
        RAISE EXCEPTION 'Student % is not actively enrolled in module %',
            p_student_id, p_module_id;
    END IF;

    INSERT INTO TutoringSession (
        StudentID, ModuleID, RequestedDate, Status, StudentNote
    )
    VALUES (
        p_student_id, p_module_id, p_requested_date, 'Requested', p_student_note
    );
END;
$$;

CREATE OR REPLACE PROCEDURE sp_create_support_request(
    IN p_student_id INTEGER,
    IN p_category_id INTEGER,
    IN p_subject VARCHAR(150),
    IN p_description VARCHAR(2000),
    IN p_consent_given BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Student WHERE StudentID = p_student_id) THEN
        RAISE EXCEPTION 'Student % does not exist', p_student_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM SupportCategory WHERE CategoryID = p_category_id) THEN
        RAISE EXCEPTION 'Support category % does not exist', p_category_id;
    END IF;

    INSERT INTO SupportRequest (
        StudentID, CategoryID, Subject, Description, ConsentGiven
    )
    VALUES (
        p_student_id, p_category_id, p_subject, p_description, p_consent_given
    );
END;
$$;

CREATE OR REPLACE PROCEDURE sp_mark_notification_read(
    IN p_student_id INTEGER,
    IN p_notification_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Notification
       SET Status = 'Read', ReadDate = CURRENT_TIMESTAMP
     WHERE NotificationID = p_notification_id
       AND StudentID = p_student_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Notification % was not found for student %',
            p_notification_id, p_student_id;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_student_module_mark(
    p_enrolment_id INTEGER
)
RETURNS NUMERIC(5,2)
LANGUAGE sql
STABLE
AS $$
    SELECT ROUND(COALESCE(SUM(r.Score * a.WeightPercent / 100), 0), 2)
      FROM Result r
      JOIN Assessment a ON a.AssessmentID = r.AssessmentID
     WHERE r.EnrolmentID = p_enrolment_id;
$$;

CREATE OR REPLACE FUNCTION fn_student_progress(
    p_student_id INTEGER
)
RETURNS TABLE (
    enrolment_id INTEGER,
    module_code VARCHAR(20),
    module_name VARCHAR(150),
    academic_year SMALLINT,
    enrolment_status VARCHAR(30),
    weighted_mark NUMERIC(5,2)
)
LANGUAGE sql
STABLE
AS $$
    SELECT e.EnrolmentID,
           m.ModuleCode,
           m.Name,
           e.AcademicYear,
           e.Status,
           fn_student_module_mark(e.EnrolmentID)
      FROM Enrolment e
      JOIN Module m ON m.ModuleID = e.ModuleID
     WHERE e.StudentID = p_student_id
     ORDER BY e.AcademicYear DESC, m.ModuleCode;
$$;

CREATE OR REPLACE VIEW vw_student_progress AS
SELECT s.StudentID,
       s.StudentNumber,
       s.FirstName,
       s.LastName,
       e.EnrolmentID,
       e.AcademicYear,
       e.Status AS EnrolmentStatus,
       m.ModuleCode,
       m.Name AS ModuleName,
       fn_student_module_mark(e.EnrolmentID) AS WeightedMark
  FROM Student s
  JOIN Enrolment e ON e.StudentID = s.StudentID
  JOIN Module m ON m.ModuleID = e.ModuleID;

CREATE OR REPLACE VIEW vw_student_assessment_results AS
SELECT e.StudentID,
       e.EnrolmentID,
       m.ModuleCode,
       m.Name AS ModuleName,
       a.Title AS AssessmentTitle,
       a.AssessmentType,
       a.WeightPercent,
       r.Score,
       r.Grade,
       r.RecordedDate
  FROM Result r
  JOIN Enrolment e ON e.EnrolmentID = r.EnrolmentID
  JOIN Assessment a ON a.AssessmentID = r.AssessmentID
  JOIN Module m ON m.ModuleID = e.ModuleID;
