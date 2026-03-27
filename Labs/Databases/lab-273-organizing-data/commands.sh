#!/bin/bash
# Lab 273 — Organizing Data
# AWS re/Start Programme
# Commands reference — run inside Session Manager terminal

# ─── Task 1: Connect to the Command Host ───────────────────────

# Elevate to root and navigate to ec2-user home
sudo su
cd /home/ec2-user/

# Connect to MariaDB
mysql -u root --password='re:St@rt!9'

# ─── Task 2: Query the world Database ─────────────────────────

# Confirm world database is available
SHOW DATABASES;

# Review all rows and columns in country table
SELECT * FROM world.country;

# Filter by region, order by population descending
SELECT Region, Name, Population FROM world.country
WHERE Region = 'Australia and New Zealand'
ORDER By Population desc;

# GROUP BY with SUM() — aggregate total population per region
SELECT Region, SUM(Population)
FROM world.country
WHERE Region = 'Australia and New Zealand'
GROUP By Region
ORDER By SUM(Population) desc;

# Window function — running total using OVER() with PARTITION BY and SUM()
SELECT Region, Name, Population,
  SUM(Population) OVER(partition by Region ORDER BY Population) as 'Running Total'
FROM world.country
WHERE Region = 'Australia and New Zealand';

# Window function — running total + RANK() combined
SELECT Region, Name, Population,
  SUM(Population) OVER(partition by Region ORDER BY Population) as 'Running Total',
  RANK() over(partition by region ORDER BY population) as 'Ranked'
FROM world.country
WHERE region = 'Australia and New Zealand';

# ─── Challenge: Rank all countries in every region ────────────

SELECT Region, Name, Population,
  RANK() OVER(partition by Region ORDER BY Population desc) as 'Ranked'
FROM world.country
ORDER BY Region, Ranked;

# ─── Git — stage, commit, push ────────────────────────────────

# Run from your local repo root (Mac terminal, not Session Manager)
# cd ~/Desktop/AWS-reStart-Journey/Labs/Databases/lab-273-organizing-data

git add README.md commands.sh lab-273-organizing-data.docx screenshots/
git commit -m "Add Lab 273 — Organizing Data (GROUP BY, OVER, RANK)"
git push origin main
