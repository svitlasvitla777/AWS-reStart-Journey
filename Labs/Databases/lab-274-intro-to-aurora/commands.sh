#!/bin/bash
# Lab 274 — Introduction to Amazon Aurora
# AWS re/Start Programme
# All commands run during this lab

# ─── Task 3: Configure EC2 to Connect to Aurora ───────────────────────────────

# Install MariaDB client
sudo yum install mariadb -y

# Connect to Aurora (replace endpoint with your actual writer endpoint from RDS console)
mysql -u admin --password='admin123' -h aurora.cluster-cnvedsxuwk0.us-west-2.rds.amazonaws.com

# ─── Task 4: Create Table, Insert Records, Query ──────────────────────────────

# List available databases
SHOW DATABASES;

# Switch to the world database
USE world;

# Create the country table
CREATE TABLE `country` (
  `Code` CHAR(3) NOT NULL DEFAULT '',
  `Name` CHAR(52) NOT NULL DEFAULT '',
  `Continent` enum('Asia','Europe','North America','Africa','Oceania','Antarctica','South America') NOT NULL DEFAULT 'Asia',
  `Region` CHAR(26) NOT NULL DEFAULT '',
  `SurfaceArea` FLOAT(10,2) NOT NULL DEFAULT '0.00',
  `IndepYear` SMALLINT(6) DEFAULT NULL,
  `Population` INT(11) NOT NULL DEFAULT '0',
  `LifeExpectancy` FLOAT(3,1) DEFAULT NULL,
  `GNP` FLOAT(10,2) DEFAULT NULL,
  `GNPOld` FLOAT(10,2) DEFAULT NULL,
  `LocalName` CHAR(45) NOT NULL DEFAULT '',
  `GovernmentForm` CHAR(45) NOT NULL DEFAULT '',
  `Capital` INT(11) DEFAULT NULL,
  `Code2` CHAR(2) NOT NULL DEFAULT '',
  PRIMARY KEY (`Code`)
);

# Insert records
INSERT INTO `country` VALUES ('GAB','Gabon','Africa','Central Africa',267668.00,1960,1226000,50.1,5493.00,5279.00,'Le Gabon','Republic',902,'GA');
INSERT INTO `country` VALUES ('IRL','Ireland','Europe','British Islands',70273.00,1921,3775100,76.8,75921.00,73132.00,'Ireland/Éire','Republic',1447,'IE');
INSERT INTO `country` VALUES ('THA','Thailand','Asia','Southeast Asia',513115.00,1350,61399000,68.6,116416.00,153907.00,'Prathet Thai','Constitutional Monarchy',3320,'TH');
INSERT INTO `country` VALUES ('CRI','Costa Rica','North America','Central America',51100.00,1821,4023000,75.8,10226.00,9757.00,'Costa Rica','Republic',584,'CR');
INSERT INTO `country` VALUES ('AUS','Australia','Oceania','Australia and New Zealand',7741220.00,1901,18886000,79.8,351182.00,392911.00,'Australia','Constitutional Monarchy, Federation',135,'AU');

# Query: countries with GNP > 35000 AND Population > 10000000
SELECT * FROM country WHERE GNP > 35000 AND Population > 10000000;

# ─── Git ──────────────────────────────────────────────────────────────────────
# cd ~/Desktop/AWS-reStart-Journey/Labs/Databases/lab-274-intro-to-aurora
# git add .
# git commit -m "Add Lab 274 - Introduction to Amazon Aurora"
# git push origin main
