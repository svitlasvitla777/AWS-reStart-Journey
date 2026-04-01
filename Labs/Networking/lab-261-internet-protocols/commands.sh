#!/bin/bash
# =============================================================================
# LAB 162 — Challenge Lab: Build Your DB Server and Interact With Your DB
# AWS re/Start Programme
# Region: us-west-2  |  Server: Aurora MySQL 3.10.3 (MySQL 8.0.42)
# =============================================================================

# -----------------------------------------------------------------------------
# STEP 4 — SSH key permissions and connect to LinuxServer
# -----------------------------------------------------------------------------
chmod 400 ~/Downloads/labsuser.pem
ssh -i ~/Downloads/labsuser.pem ec2-user@44.246.227.45

# -----------------------------------------------------------------------------
# STEP 5 — Install MySQL client (run on LinuxServer)
# -----------------------------------------------------------------------------
sudo yum install -y mysql

# Connect to RDS Aurora instance
mysql -h lab162-cluster-instance-1.cc4wsbuoc2jx.us-west-2.rds.amazonaws.com -u admin -p

# -----------------------------------------------------------------------------
# STEP 6 — Select database and create RESTART table (run inside MySQL prompt)
# -----------------------------------------------------------------------------
USE restart_db;

CREATE TABLE RESTART (
  StudentID      INT PRIMARY KEY,
  StudentName    VARCHAR(100),
  RestartCity    VARCHAR(100),
  GraduationDate DATETIME
);

# -----------------------------------------------------------------------------
# STEP 7 — Insert 10 sample rows into RESTART
# -----------------------------------------------------------------------------
INSERT INTO RESTART VALUES
(1,  'Alice Brown',   'London',    '2024-06-15 09:00:00'),
(2,  'Bob Smith',     'Dublin',    '2024-06-15 09:00:00'),
(3,  'Clara Jones',   'Berlin',    '2024-07-20 09:00:00'),
(4,  'David Lee',     'Paris',     '2024-07-20 09:00:00'),
(5,  'Emma Wilson',   'Amsterdam', '2024-08-10 09:00:00'),
(6,  'Frank Taylor',  'Warsaw',    '2024-08-10 09:00:00'),
(7,  'Grace Martin',  'Madrid',    '2024-09-01 09:00:00'),
(8,  'Henry Clark',   'Rome',      '2024-09-01 09:00:00'),
(9,  'Isla Anderson', 'Vienna',    '2024-10-05 09:00:00'),
(10, 'Jack Thompson', 'Zurich',    '2024-10-05 09:00:00');

# -----------------------------------------------------------------------------
# STEP 8 — Select all rows from RESTART
# -----------------------------------------------------------------------------
SELECT * FROM RESTART;

# -----------------------------------------------------------------------------
# STEP 9 — Create CLOUD_PRACTITIONER table
# -----------------------------------------------------------------------------
CREATE TABLE CLOUD_PRACTITIONER (
  StudentID         INT PRIMARY KEY,
  CertificationDate DATETIME
);

# -----------------------------------------------------------------------------
# STEP 10 — Insert 5 sample rows into CLOUD_PRACTITIONER
# -----------------------------------------------------------------------------
INSERT INTO CLOUD_PRACTITIONER VALUES
(1, '2024-09-10 10:00:00'),
(3, '2024-10-01 10:00:00'),
(5, '2024-10-15 10:00:00'),
(7, '2024-11-05 10:00:00'),
(9, '2024-11-20 10:00:00');

# -----------------------------------------------------------------------------
# STEP 11 — Select all rows from CLOUD_PRACTITIONER
# -----------------------------------------------------------------------------
SELECT * FROM CLOUD_PRACTITIONER;

# -----------------------------------------------------------------------------
# STEP 12 — Inner join: StudentID, StudentName, CertificationDate
# -----------------------------------------------------------------------------
SELECT r.StudentID, r.StudentName, cp.CertificationDate
FROM RESTART r
INNER JOIN CLOUD_PRACTITIONER cp
  ON r.StudentID = cp.StudentID;

# -----------------------------------------------------------------------------
# STEP 13 — Exit MySQL
# -----------------------------------------------------------------------------
EXIT;

# -----------------------------------------------------------------------------
# GIT — Stage, commit, and push to GitHub
# -----------------------------------------------------------------------------
cd ~/Desktop/AWS-reStart-Journey/Labs/Databases/lab-162-challenge-db-server
git add .
git commit -m "Add Lab 162: Challenge DB Server — Aurora MySQL, RDS, SSH, joins"
git push origin main
