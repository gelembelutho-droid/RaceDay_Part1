-- ============================================================
-- DATABASE: RaceDay System
-- AUTHOR: [Your Name/Student ID]
-- DATE: 2026-09-03
-- DESCRIPTION: Full database schema for RaceDay event management
-- SQL VERSION: SQL Server (SSMS)
-- ============================================================

-- ============================================================
-- SECTION 0: CREATE AND USE DATABASE
-- ============================================================

USE master;
GO

-- Check if database exists and drop it (for clean creation)
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'RaceDay')
BEGIN
    ALTER DATABASE RaceDay SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDay;
    PRINT 'Database RaceDay dropped successfully.';
END
ELSE
BEGIN
    PRINT 'Database RaceDay does not exist. Creating new one.';
END
GO

-- Create the RaceDay database
CREATE DATABASE RaceDay;
GO
PRINT 'Database RaceDay created successfully.';
GO

-- Switch to the RaceDay database
USE RaceDay;
GO

-- ============================================================
-- SECTION 1: CREATE TABLES
-- ============================================================

-- 1. USER Table
-- Stores common profile information for all users
CREATE TABLE dbo.[User] (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NULL,
    gender CHAR(1) NULL CHECK (gender IN ('M', 'F', 'O')),
    phone VARCHAR(20) NULL,
    emergency_contact VARCHAR(100) NULL,
    created_at DATETIME DEFAULT GETDATE() NOT NULL
);
PRINT 'Table User created.';
GO

-- 2. EVENT Table
-- Stores event details created by Organisers
CREATE TABLE dbo.Event (
    event_id INT IDENTITY(1,1) PRIMARY KEY,
    organizer_id INT NOT NULL,
    event_name VARCHAR(100) NOT NULL,
    event_date DATE NOT NULL,
    location VARCHAR(200) NULL,
    city VARCHAR(50) NULL,
    country VARCHAR(50) NULL,
    description NVARCHAR(MAX) NULL,
    created_at DATETIME DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_Event_Organizer FOREIGN KEY (organizer_id) 
        REFERENCES dbo.[User](user_id)
);
PRINT 'Table Event created.';
GO

-- 3. RACE Table
-- Defines individual races within an Event
CREATE TABLE dbo.Race (
    race_id INT IDENTITY(1,1) PRIMARY KEY,
    event_id INT NOT NULL,
    race_name VARCHAR(100) NOT NULL,
    distance_km DECIMAL(5,2) NOT NULL CHECK (distance_km > 0),
    start_time DATETIME NOT NULL,
    end_time DATETIME NULL,
    age_group VARCHAR(50) NULL,
    max_participants INT NULL CHECK (max_participants > 0),
    created_at DATETIME DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_Race_Event FOREIGN KEY (event_id) 
        REFERENCES dbo.Event(event_id)
);
PRINT 'Table Race created.';
GO

-- 4. SPONSOR Table
-- Stores sponsor company details
CREATE TABLE dbo.Sponsor (
    sponsor_id INT IDENTITY(1,1) PRIMARY KEY,
    sponsor_name VARCHAR(100) NOT NULL,
    website VARCHAR(200) NULL,
    contact_email VARCHAR(100) NULL,
    phone VARCHAR(20) NULL,
    created_at DATETIME DEFAULT GETDATE() NOT NULL
);
PRINT 'Table Sponsor created.';
GO

-- 5. EVENT_SPONSOR Table (Junction for Many-to-Many)
-- Links Events to Sponsors
CREATE TABLE dbo.EventSponsor (
    event_id INT NOT NULL,
    sponsor_id INT NOT NULL,
    sponsorship_level VARCHAR(50) NULL,
    created_at DATETIME DEFAULT GETDATE() NOT NULL,
    CONSTRAINT PK_EventSponsor PRIMARY KEY (event_id, sponsor_id),
    CONSTRAINT FK_EventSponsor_Event FOREIGN KEY (event_id) 
        REFERENCES dbo.Event(event_id),
    CONSTRAINT FK_EventSponsor_Sponsor FOREIGN KEY (sponsor_id) 
        REFERENCES dbo.Sponsor(sponsor_id)
);
PRINT 'Table EventSponsor created.';
GO

-- 6. REGISTRATION Table
-- Links Participants to Races
CREATE TABLE dbo.Registration (
    registration_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    race_id INT NOT NULL,
    registration_date DATETIME DEFAULT GETDATE() NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' NOT NULL 
        CHECK (status IN ('pending', 'confirmed', 'cancelled')),
    bib_number VARCHAR(20) UNIQUE NULL,
    created_at DATETIME DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_Registration_User FOREIGN KEY (user_id) 
        REFERENCES dbo.[User](user_id),
    CONSTRAINT FK_Registration_Race FOREIGN KEY (race_id) 
        REFERENCES dbo.Race(race_id),
    CONSTRAINT UQ_Registration_UserRace UNIQUE (user_id, race_id)
);
PRINT 'Table Registration created.';
GO

-- 7. RESULT Table
-- Stores race results for each registration
CREATE TABLE dbo.Result (
    result_id INT IDENTITY(1,1) PRIMARY KEY,
    registration_id INT NOT NULL,
    finish_time TIME NULL,
    overall_rank INT NULL,
    age_group_rank INT NULL,
    pace_per_km DECIMAL(4,2) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DNS' 
        CHECK (status IN ('DNS', 'DNF', 'finished')),
    created_at DATETIME DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_Result_Registration FOREIGN KEY (registration_id) 
        REFERENCES dbo.Registration(registration_id),
    CONSTRAINT UQ_Result_Registration UNIQUE (registration_id)
);
PRINT 'Table Result created.';
GO

-- 8. PAYMENT Table
-- Stores payment information for registrations
CREATE TABLE dbo.Payment (
    payment_id INT IDENTITY(1,1) PRIMARY KEY,
    registration_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    payment_date DATETIME DEFAULT GETDATE() NOT NULL,
    payment_method VARCHAR(20) NULL 
        CHECK (payment_method IN ('credit_card', 'paypal', 'bank_transfer')),
    transaction_id VARCHAR(100) UNIQUE NULL,
    created_at DATETIME DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_Payment_Registration FOREIGN KEY (registration_id) 
        REFERENCES dbo.Registration(registration_id),
    CONSTRAINT UQ_Payment_Registration UNIQUE (registration_id)
);
PRINT 'Table Payment created.';
GO

-- ============================================================
-- SECTION 2: CREATE INDEXES FOR PERFORMANCE
-- ============================================================

-- User indexes
CREATE INDEX IX_User_Email ON dbo.[User](email);
CREATE INDEX IX_User_FullName ON dbo.[User](full_name);
GO

-- Event indexes
CREATE INDEX IX_Event_Organizer ON dbo.Event(organizer_id);
CREATE INDEX IX_Event_Date ON dbo.Event(event_date);
GO

-- Race indexes
CREATE INDEX IX_Race_Event ON dbo.Race(event_id);
CREATE INDEX IX_Race_StartTime ON dbo.Race(start_time);
GO

-- Registration indexes
CREATE INDEX IX_Registration_User ON dbo.Registration(user_id);
CREATE INDEX IX_Registration_Race ON dbo.Registration(race_id);
CREATE INDEX IX_Registration_Status ON dbo.Registration(status);
GO

-- Result indexes
CREATE INDEX IX_Result_Registration ON dbo.Result(registration_id);
CREATE INDEX IX_Result_OverallRank ON dbo.Result(overall_rank);
GO

-- Payment indexes
CREATE INDEX IX_Payment_Registration ON dbo.Payment(registration_id);
CREATE INDEX IX_Payment_Transaction ON dbo.Payment(transaction_id);
GO

-- EventSponsor indexes
CREATE INDEX IX_EventSponsor_Sponsor ON dbo.EventSponsor(sponsor_id);
GO

PRINT 'All indexes created successfully.';
GO

-- ============================================================
-- SECTION 3: INSERT SAMPLE DATA
-- ============================================================

-- 3.1: Seed Users (2 Organizers + 2 Participants)
PRINT 'Inserting users...';
INSERT INTO dbo.[User] (email, password_hash, full_name, date_of_birth, gender, phone, emergency_contact)
VALUES 
    ('emma62.johnson@runco.com', 'hash_123456', 'Sarah Johnson', '1985-03-15', 'F', '+1-555-0101', 'Mike Johnson - +1-555-0102'),
    ('lamineyaml.chen@raceplus.com', 'hash_789012', 'Michael Chen', '1978-11-22', 'M', '+1-555-0201', 'Lisa Chen - +1-555-0202'),
    ('erinjuiles@email.com', 'hash_345678', 'Emma Wilson', '1992-07-08', 'F', '+1-555-0301', 'David Wilson - +1-555-0302'),
    ('james.alerhen@email.com', 'hash_901234', 'James Rodriguez', '1988-09-23', 'M', '+1-555-0401', 'Anna Rodriguez - +1-555-0402');
PRINT 'Users inserted.';
GO

-- 3.2: Seed Events (3 events)
PRINT 'Inserting events...';
INSERT INTO dbo.Event (organizer_id, event_name, event_date, location, city, country, description)
VALUES 
    (1, 'City Marathon 2026', '2026-11-15', 'Downtown Convention Center', 'New York', 'USA', 'Annual city marathon featuring full and half marathon distances'),
    (1, 'Spring 5K Fun Run', '2026-05-10', 'Central Park', 'Boston', 'USA', 'Family-friendly 5K run with proceeds going to local charities'),
    (2, 'Trail Challenge Series', '2026-08-22', 'Mountain View Park', 'Denver', 'USA', 'Challenging trail runs through the Rocky Mountain foothills');
PRINT 'Events inserted.';
GO

-- 3.3: Seed Sponsors (4 sponsors)
PRINT 'Inserting sponsors...';
INSERT INTO dbo.Sponsor (sponsor_name, website, contact_email, phone)
VALUES 
    ('Nike Running', 'www.nike.com/running', 'sponsors@nike.com', '+1-800-555-1000'),
    ('Gatorade', 'www.gatorade.com', 'events@gatorade.com', '+1-800-555-2000'),
    ('Apple Sports', 'www.apple.com/watch', 'sports@apple.com', '+1-800-555-3000'),
    ('Brooks Running', 'www.brooksrunning.com', 'sponsorship@brooks.com', '+1-800-555-4000');
PRINT 'Sponsors inserted.';
GO

-- 3.4: Link Sponsors to Events (Many-to-Many)
PRINT 'Linking sponsors to events...';
INSERT INTO dbo.EventSponsor (event_id, sponsor_id, sponsorship_level)
VALUES 
    (1, 1, 'Platinum'),
    (1, 2, 'Gold'),
    (2, 1, 'Silver'),
    (2, 3, 'Gold'),
    (3, 4, 'Platinum'),
    (3, 2, 'Silver');
PRINT 'EventSponsors inserted.';
GO

-- 3.5: Seed Races (8 races across 3 events)
PRINT 'Inserting races...';
INSERT INTO dbo.Race (event_id, race_name, distance_km, start_time, end_time, age_group, max_participants)
VALUES 
    -- Event 1: City Marathon 2026
    (1, 'Full Marathon', 42.20, '2026-11-15 07:00:00', '2026-11-15 13:00:00', NULL, 2000),
    (1, 'Half Marathon', 21.10, '2026-11-15 08:30:00', '2026-11-15 12:00:00', NULL, 3000),
    (1, '10K Run', 10.00, '2026-11-15 09:30:00', '2026-11-15 11:30:00', '16+', 1500),
    -- Event 2: Spring 5K Fun Run
    (2, '5K Competitive', 5.00, '2026-05-10 09:00:00', '2026-05-10 11:00:00', '18+', 500),
    (2, '5K Family Walk', 5.00, '2026-05-10 10:30:00', '2026-05-10 12:30:00', 'All Ages', 300),
    (2, 'Kids Fun Run', 1.00, '2026-05-10 11:00:00', '2026-05-10 12:00:00', '5-12', 100),
    -- Event 3: Trail Challenge Series
    (3, '10K Trail Run', 10.00, '2026-08-22 07:30:00', '2026-08-22 11:00:00', '18+', 400),
    (3, '20K Trail Run', 20.00, '2026-08-22 06:00:00', '2026-08-22 11:30:00', '21+', 200);
PRINT 'Races inserted.';
GO

-- 3.6: Seed Registrations (8 registrations - All bib numbers are unique)
PRINT 'Inserting registrations...';
INSERT INTO dbo.Registration (user_id, race_id, registration_date, status, bib_number)
VALUES 
    -- Emma Wilson's registrations (user_id = 3)
    (3, 1, '2026-09-15 10:30:00', 'confirmed', 'M1001'),  -- Full Marathon
    (3, 2, '2026-09-20 14:15:00', 'confirmed', 'M3002'),  -- Half Marathon
    (3, 3, '2026-10-01 09:00:00', 'pending', 'P5001'),    -- 10K Run
    -- James Rodriguez's registrations (user_id = 4)
    (4, 4, '2026-09-18 11:45:00', 'confirmed', 'H2003'),  -- 5K Competitive
    (4, 5, '2026-09-25 16:20:00', 'confirmed', 'F4004'),  -- 5K Family Walk
    (4, 7, '2026-10-05 08:30:00', 'confirmed', 'T7005'),  -- 10K Trail Run
    -- Additional registrations
    (3, 6, '2026-09-28 13:10:00', 'cancelled', 'C6001'),  -- Kids Fun Run (cancelled)
    (4, 8, '2026-10-02 10:00:00', 'confirmed', 'T8006');  -- 20K Trail Run
PRINT 'Registrations inserted.';
GO

-- 3.7: Seed Results (7 results - All registration_ids exist)
PRINT 'Inserting results...';
INSERT INTO dbo.Result (registration_id, finish_time, overall_rank, age_group_rank, pace_per_km, status)
VALUES 
    -- Registration 1: Emma - Full Marathon
    (1, '03:45:22', 245, 28, 5.30, 'finished'),
    -- Registration 2: Emma - Half Marathon
    (2, '03:50:15', 256, 32, 5.45, 'finished'),
    -- Registration 3: Emma - 10K Run
    (3, '00:48:30', 134, 18, 4.85, 'finished'),
    -- Registration 4: James - 5K Competitive
    (4, '02:08:45', 78, 12, 6.10, 'finished'),
    -- Registration 5: James - 5K Family Walk
    (5, '00:22:15', 45, 8, 4.45, 'finished'),
    -- Registration 6: James - 10K Trail Run
    (6, '01:15:30', 67, 15, 7.55, 'finished'),
    -- Registration 8: James - 20K Trail Run
    (8, '00:19:50', 12, 3, 3.98, 'finished');
    -- Registration 7 is cancelled, so no result
PRINT 'Results inserted.';
GO

-- 3.8: Seed Payments (7 payments - All registration_ids exist)
PRINT 'Inserting payments...';
INSERT INTO dbo.Payment (registration_id, amount, payment_date, payment_method, transaction_id)
VALUES 
    (1, 75.00, '2026-09-15 10:35:00', 'credit_card', 'TXN-1001-ABC'),
    (2, 45.00, '2026-09-20 14:20:00', 'paypal', 'TXN-3002-DEF'),
    (3, 25.00, '2026-10-01 09:05:00', 'bank_transfer', 'TXN-5003-GHI'),
    (4, 75.00, '2026-09-18 11:50:00', 'credit_card', 'TXN-2004-JKL'),
    (5, 25.00, '2026-09-25 16:25:00', 'paypal', 'TXN-4005-MNO'),
    (6, 50.00, '2026-10-05 08:35:00', 'credit_card', 'TXN-7006-PQR'),
    (8, 25.00, '2026-10-02 10:05:00', 'bank_transfer', 'TXN-8007-STU');
PRINT 'Payments inserted.';
GO

PRINT 'All sample data inserted successfully.';
GO

-- ============================================================
-- SECTION 4: VERIFICATION QUERIES
-- ============================================================

-- Show current database
SELECT DB_NAME() AS CurrentDatabase;
GO

-- Show all users with their roles
SELECT 
    user_id,
    full_name,
    email,
    CASE 
        WHEN user_id IN (1, 2) THEN 'Organizer'
        ELSE 'Participant'
    END AS role
FROM dbo.[User]
ORDER BY user_id;
GO

-- Show all events with race count
SELECT 
    e.event_id,
    e.event_name,
    e.event_date,
    u.full_name AS organizer,
    COUNT(r.race_id) AS race_count
FROM dbo.Event e
JOIN dbo.[User] u ON e.organizer_id = u.user_id
LEFT JOIN dbo.Race r ON e.event_id = r.event_id
GROUP BY e.event_id, e.event_name, e.event_date, u.full_name
ORDER BY e.event_date;
GO

-- Show all registrations with participant and race details
SELECT 
    reg.registration_id,
    u.full_name AS participant,
    r.race_name,
    e.event_name,
    reg.status,
    reg.bib_number,
    CASE 
        WHEN reg.status = 'confirmed' AND res.result_id IS NOT NULL THEN 'Finished'
        WHEN reg.status = 'confirmed' AND res.result_id IS NULL THEN 'Registered'
        ELSE reg.status
    END AS race_status
FROM dbo.Registration reg
JOIN dbo.[User] u ON reg.user_id = u.user_id
JOIN dbo.Race r ON reg.race_id = r.race_id
JOIN dbo.Event e ON r.event_id = e.event_id
LEFT JOIN dbo.Result res ON reg.registration_id = res.registration_id
ORDER BY reg.registration_id;
GO

-- Show event sponsorship summary
SELECT 
    e.event_id,
    e.event_name,
    COUNT(DISTINCT es.sponsor_id) AS sponsor_count,
    STUFF(
        (SELECT ', ' + s.sponsor_name 
         FROM dbo.EventSponsor es2 
         JOIN dbo.Sponsor s ON es2.sponsor_id = s.sponsor_id
         WHERE es2.event_id = e.event_id
         FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS sponsors
FROM dbo.Event e
LEFT JOIN dbo.EventSponsor es ON e.event_id = es.event_id
GROUP BY e.event_id, e.event_name
ORDER BY e.event_id;
GO

-- Show payment summary per event
SELECT 
    e.event_name,
    COUNT(p.payment_id) AS payments,
    ISNULL(SUM(p.amount), 0) AS total_revenue,
    ISNULL(AVG(p.amount), 0) AS avg_payment
FROM dbo.Event e
JOIN dbo.Race r ON e.event_id = r.event_id
JOIN dbo.Registration reg ON r.race_id = reg.race_id
JOIN dbo.Payment p ON reg.registration_id = p.registration_id
GROUP BY e.event_id, e.event_name
ORDER BY total_revenue DESC;
GO

-- ============================================================
-- SECTION 5: STORED PROCEDURE
-- ============================================================

-- Get event statistics
CREATE OR ALTER PROCEDURE dbo.sp_GetEventStatistics
    @event_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        e.event_id,
        e.event_name,
        e.event_date,
        COUNT(DISTINCT r.race_id) AS total_races,
        COUNT(DISTINCT reg.registration_id) AS total_registrations,
        COUNT(DISTINCT reg.user_id) AS unique_participants,
        COUNT(DISTINCT res.result_id) AS finished_races,
        COUNT(DISTINCT p.payment_id) AS paid_registrations,
        ISNULL(SUM(p.amount), 0) AS total_revenue,
        COUNT(DISTINCT es.sponsor_id) AS sponsor_count
    FROM dbo.Event e
    LEFT JOIN dbo.Race r ON e.event_id = r.event_id
    LEFT JOIN dbo.Registration reg ON r.race_id = reg.race_id
    LEFT JOIN dbo.Result res ON reg.registration_id = res.registration_id
    LEFT JOIN dbo.Payment p ON reg.registration_id = p.registration_id
    LEFT JOIN dbo.EventSponsor es ON e.event_id = es.event_id
    WHERE (@event_id IS NULL OR e.event_id = @event_id)
    GROUP BY e.event_id, e.event_name, e.event_date
    ORDER BY e.event_date;
END
GO

-- ============================================================
-- SECTION 6: DEMO STORED PROCEDURE EXECUTION
-- ============================================================

-- Get statistics for all events
EXEC dbo.sp_GetEventStatistics;
GO

-- Get statistics for a specific event (City Marathon)
EXEC dbo.sp_GetEventStatistics @event_id = 1;
GO

-- ============================================================
-- SECTION 7: FINAL VERIFICATION
-- ============================================================

-- Show all tables in the RaceDay database
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO
-- Final success message
PRINT '============================================';
PRINT 'DATABASE CREATION COMPLETE!';
PRINT '============================================';
PRINT 'Tables created: 8';
PRINT 'Sample data inserted successfully';
PRINT 'All constraints and indexes created';
PRINT '============================================';
GO

-- ============================================================
-- END OF SCRIPT
-- ============================================================
