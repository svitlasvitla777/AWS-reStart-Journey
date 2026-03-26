#!/bin/bash
# Lab 271 — Performing a Conditional Search
# All commands run during this lab

# ── Task 1: Connect to the Command Host ──────────────────────────────────────
sudo su
cd /home/ec2-user/
mysql -u root --password='re:St@rt!9'

# ── Task 2: Query the world database ─────────────────────────────────────────

# Show available databases
SHOW DATABASES;

# Review full country table
SELECT * FROM world.country;

# WHERE with AND operator
SELECT Name, Capital, Region, SurfaceArea, Population FROM world.country WHERE Population >= 50000000 AND Population <= 100000000;

# BETWEEN operator (same result as above)
SELECT Name, Capital, Region, SurfaceArea, Population FROM world.country WHERE Population BETWEEN 50000000 AND 100000000;

# LIKE with SUM
SELECT sum(Population) from world.country WHERE Region LIKE "%Europe%";

# AS column alias
SELECT sum(population) as "Europe Population Total" from world.country WHERE region LIKE "%Europe%";

# LOWER function for case-insensitive search
SELECT Name, Capital, Region, SurfaceArea, Population from world.country WHERE LOWER(Region) LIKE "%central%";

# ── Challenge ─────────────────────────────────────────────────────────────────
SELECT SUM(SurfaceArea) as "N. America Surface Area", SUM(Population) as "N. America Population" FROM world.country WHERE Region = "North America";
