#!/bin/bash
# Lab 272 — Working with Functions
# AWS re/Start Programme
# All commands run during this lab, in order of execution.

# ── TASK 1: Connect to the Command Host ──────────────────────────────────────

sudo su
cd /home/ec2-user/

mysql -u root --password='re:St@rt!9'

# ── TASK 2: Query the world Database ─────────────────────────────────────────

# Show available databases
SHOW DATABASES;

# View all rows in the country table
SELECT * FROM world.country;

# Aggregate functions: SUM, AVG, MAX, MIN, COUNT
SELECT sum(Population), avg(Population), max(Population), min(Population), count(Population) FROM world.country;

# SUBSTRING_INDEX — extract first word of each region name
SELECT Region, substring_index(Region, " ", 1) FROM world.country;

# SUBSTRING_INDEX in a WHERE clause — filter regions beginning with "Southern"
SELECT Name, Region from world.country WHERE substring_index(Region, " ", 1) = "Southern";

# LENGTH and TRIM — regions with fewer than 10 characters (with duplicates)
SELECT Region FROM world.country WHERE LENGTH(TRIM(Region)) < 10;

# DISTINCT — remove duplicate region names
SELECT DISTINCT(Region) FROM world.country WHERE LENGTH(TRIM(Region)) < 10;

# Challenge — split Micronesia/Caribbean into two named columns
SELECT Name,
  substring_index(Region, "/", 1)  as "Region Name 1",
  substring_index(region, "/", -1) as "Region Name 2"
FROM world.country
WHERE Region = "Micronesia/Caribbean";

# ── GIT ───────────────────────────────────────────────────────────────────────

cd ~\Desktop\AWS-reStart-Journey\Labs\Databases\lab-272-working-with-functions
git add .
git commit -m "Lab 272: Working with Functions — MariaDB SQL functions complete"
git push origin main
