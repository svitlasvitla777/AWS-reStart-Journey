#!/bin/bash
# Lab 179 — Migrating to Amazon RDS
# AWS re/Start Programme
# Region: us-west-2 | CafeVpcID: vpc-0d94dfe2aabb67a15

# ─── TASK 2.2 — Configure AWS CLI (run on CLI Host) ─────────────────────────
aws configure
# AWS Access Key ID:     [from Details panel — do not commit]
# AWS Secret Access Key: [from Details panel — do not commit]
# Default region name:   us-west-2
# Default output format: json

# ─── TASK 2.3 — Create security group ───────────────────────────────────────
aws ec2 create-security-group \
  --group-name CafeDatabaseSG \
  --description "Security group for Cafe database" \
  --vpc-id vpc-0d94dfe2aabb67a15
# GroupId returned: sg-0774228eadec3823d

# Add inbound rule: TCP 3306 from CafeSecurityGroup only
aws ec2 authorize-security-group-ingress \
  --group-id sg-0774228eadec3823d \
  --protocol tcp --port 3306 \
  --source-group sg-098c59de9c16e6b2d

# Verify
aws ec2 describe-security-groups \
  --query "SecurityGroups[*].[GroupName,GroupId,IpPermissions]" \
  --filters "Name=group-name,Values='CafeDatabaseSG'"

# Create Private Subnet 1 (us-west-2a)
aws ec2 create-subnet \
  --vpc-id vpc-0d94dfe2aabb67a15 \
  --cidr-block 10.200.2.0/23 \
  --availability-zone us-west-2a
# SubnetId: subnet-0eb071cefb24ee93e

# Create Private Subnet 2 (us-west-2b)
aws ec2 create-subnet \
  --vpc-id vpc-0d94dfe2aabb67a15 \
  --cidr-block 10.200.10.0/23 \
  --availability-zone us-west-2b
# SubnetId: subnet-087e211be9ed5b437

# Create DB subnet group
aws rds create-db-subnet-group \
  --db-subnet-group-name "CafeDB Subnet Group" \
  --db-subnet-group-description "DB subnet group for Cafe" \
  --subnet-ids subnet-0eb071cefb24ee93e subnet-087e211be9ed5b437 \
  --tags "Key=Name,Value=CafeDatabaseSubnetGroup"

# ─── TASK 2.4 — Create RDS MariaDB instance ─────────────────────────────────
# Note: 10.5.13 unavailable in us-west-2; using 10.5.29 (same branch)
aws rds create-db-instance \
  --db-instance-identifier CafeDBInstance \
  --engine mariadb \
  --engine-version 10.5.29 \
  --db-instance-class db.t3.micro \
  --allocated-storage 20 \
  --availability-zone us-west-2a \
  --db-subnet-group-name "CafeDB Subnet Group" \
  --vpc-security-group-ids sg-0774228eadec3823d \
  --no-publicly-accessible \
  --master-username root --master-user-password 'Re:Start!9'

# Poll until available (repeat every 1-2 minutes)
aws rds describe-db-instances \
  --db-instance-identifier CafeDBInstance \
  --query "DBInstances[*].[Endpoint.Address,AvailabilityZone,PreferredBackupWindow,BackupRetentionPeriod,DBInstanceStatus]"
# Endpoint: cafedbinstance.cc2xzhar0qoi.us-west-2.rds.amazonaws.com

# ─── TASK 3 — Migrate data (run on CafeInstance: i-0bab9bc6e23092ac4) ───────

# Export local database
mysqldump --user=root --password='Re:Start!9' \
  --databases cafe_db --add-drop-database > cafedb-backup.sql

# Verify backup file (5.9K)
ls -lh cafedb-backup.sql

# Restore to RDS
mysql --user=root --password='Re:Start!9' \
  --host=cafedbinstance.cc2xzhar0qoi.us-west-2.rds.amazonaws.com \
  < cafedb-backup.sql

# Verify migration
mysql --user=root --password='Re:Start!9' \
  --host=cafedbinstance.cc2xzhar0qoi.us-west-2.rds.amazonaws.com \
  cafe_db
# select * from product;   -> 9 rows
# exit

# ─── TASK 5 — Test monitoring (run on CafeInstance) ─────────────────────────
mysql --user=root --password='Re:Start!9' \
  --host=cafedbinstance.cc2xzhar0qoi.us-west-2.rds.amazonaws.com \
  cafe_db
# select * from product;
# exit

# ─── GIT — Push to GitHub ────────────────────────────────────────────────────
cd ~/Desktop/AWS-reStart-Journey/Labs/Databases/lab-179-migrating-to-amazon-rds
git add .
git commit -m "Add Lab 179: Migrating to Amazon RDS"
git push origin main
