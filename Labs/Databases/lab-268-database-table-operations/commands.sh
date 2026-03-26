#!/bin/bash
# ============================================================
# LAB 268 — Database Table Operations
# AWS re/Start Program
# All commands used in this lab, in order
# ============================================================

# ── TASK 1: Connect to the Command Host ─────────────────────

# Switch to root
sudo su

# Navigate to working directory
cd /home/ec2-user/

# Connect to MariaDB
mysql -u root --password='re:St@rt!9'


# ── TASK 2: Create a Database and a Table ───────────────────

# View existing databases
SHOW DATABASES;

# Create the world database
CREATE DATABASE world;

# Verify world was created
SHOW DATABASES;

# Create the country table
CREATE TABLE world.country (
  `Code` CHAR(3) NOT NULL DEFAULT '',
  `Name` CHAR(52) NOT NULL DEFAULT '',
  `Conitinent` enum('Asia','Europe','North America','Africa','Oceania','Antarctica','South America') NOT NULL DEFAULT 'Asia',
  `Region` CHAR(26) NOT NULL DEFAULT '',
  `SurfaceArea` FLOAT(10,2) NOT NULL DEFAULT '0.00',
  `IndepYear` SMALLINT(6) DEFAULT NULL,
  `Population` INT(11) NOT NULL DEFAULT '0',
  `LifeExpectancy` FLOAT(3,1) DEFAULT NULL,
  `GNP` FLOAT(10,2) DEFAULT NULL,
  `GNPOld` FLOAT(10,2) DEFAULT NULL,
  `LocalName` CHAR(45) NOT NULL DEFAULT '',
  `GovernmentForm` CHAR(45) NOT NULL DEFAULT '',
  `HeadOfState` CHAR(60) DEFAULT NULL,
  `Capital` INT(11) DEFAULT NULL,
  `Code2` CHAR(2) NOT NULL DEFAULT '',
  PRIMARY KEY (`Code`)
);

# Switch to world database and verify table exists
USE world;
SHOW TABLES;

# Inspect columns (spot the Conitinent typo)
SHOW COLUMNS FROM world.country;

# Fix the typo with ALTER TABLE
ALTER TABLE world.country RENAME COLUMN Conitinent TO Continent;

# Verify the fix
SHOW COLUMNS FROM world.country;


# ── CHALLENGE 1: Create the city Table ──────────────────────

CREATE TABLE world.city (`Name` CHAR(52), `Region` CHAR(26));

# Verify both tables exist
SHOW TABLES;


# ── TASK 3: Delete a Database and Tables ────────────────────

# Drop city table
DROP TABLE world.city;

# Challenge 2: Drop country table
DROP TABLE world.country;

# Verify both tables are gone
SHOW TABLES;

# Drop the world database
DROP DATABASE world;

# Verify world is gone
SHOW DATABASES;


# ── GIT: Push to GitHub ──────────────────────────────────────

# Run these from your local machine (not inside the EC2 terminal)

git add Labs/Databases/lab-268-database-table-operations/
git commit -m "Complete Lab 268 - Database Table Operations"
git push origin main
