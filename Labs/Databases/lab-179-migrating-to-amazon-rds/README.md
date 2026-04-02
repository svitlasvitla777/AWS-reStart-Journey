# Lab 179 — Migrating to Amazon RDS

## About This Lab

This lab covers migrating a live web application database from a local MariaDB instance running on an EC2 server to a fully managed Amazon RDS MariaDB instance. In a real cloud role, this kind of migration is one of the first steps in modernising legacy LAMP-stack applications — moving the database off the application server removes a single point of failure, enables automated backups with configurable retention, and decouples database scaling from application scaling.

The lab uses EC2, Amazon RDS, AWS Systems Manager Session Manager, AWS Systems Manager Parameter Store, Amazon CloudWatch, and the AWS CLI. The practical skill this demonstrates to a recruiter is the ability to design and execute a live database migration — including network configuration, security group creation, data export and import, application reconfiguration, and post-migration monitoring — entirely through the command line.

## What I Did

The lab pre-provisioned a running café web application on an EC2 instance (i-0bab9bc6e23092ac4, private IP 10.200.0.73) running a LAMP stack with a local MariaDB database, plus a separate CLI Host (private IP 10.200.0.113) with the AWS CLI installed. I connected to the CLI Host using EC2 Instance Connect, configured the AWS CLI with lab credentials, built the required VPC networking components, provisioned an RDS MariaDB 10.5.29 instance, migrated the café database using mysqldump, updated the application's database connection parameter in Parameter Store, and verified the migration by comparing order history before and after. I also observed live CloudWatch metrics for the RDS instance.

## Task 1: Generating order data on the café website

Before migrating anything, I placed an order on the café website to create data that would need to survive the migration. Order 1 was placed on 2026-03-28 at 17:42:17 — total $23.00 — containing Croissant (x2), Strawberry Blueberry Tart (x2), Strawberry Tart (x2), Coffee (x1), and Hot Chocolate (x1).

![Order History before migration](screenshots/01_order_history_before_migration.png)

## Task 2: Creating an Amazon RDS instance by using the AWS CLI

### Task 2.1: Connecting to the CLI Host instance

I connected to the CLI Host EC2 instance using EC2 Instance Connect from the AWS Management Console — no SSH key management required.

![CLI Host connected](screenshots/02_cli_host_connected.png)

### Task 2.2: Configuring the AWS CLI

```bash
aws configure
# AccessKey: AKIA3F24OA7BV5X3T4HT
# Region:    us-west-2
# Format:    json
```

### Task 2.3: Creating prerequisite components

**Create CafeDatabaseSG security group:**
```bash
aws ec2 create-security-group \
  --group-name CafeDatabaseSG \
  --description "Security group for Cafe database" \
  --vpc-id vpc-0d94dfe2aabb67a15
# GroupId returned: sg-0774228eadec3823d
```

**Add TCP 3306 inbound rule — CafeInstance access only:**
```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-0774228eadec3823d \
  --protocol tcp --port 3306 \
  --source-group sg-098c59de9c16e6b2d
```

**Verify the rule:**
```bash
aws ec2 describe-security-groups \
  --query "SecurityGroups[*].[GroupName,GroupId,IpPermissions]" \
  --filters "Name=group-name,Values='CafeDatabaseSG'"
```

![Security group verified](screenshots/03_security_group_verified.png)

**Create two private subnets in different Availability Zones:**
```bash
aws ec2 create-subnet \
  --vpc-id vpc-0d94dfe2aabb67a15 \
  --cidr-block 10.200.2.0/23 \
  --availability-zone us-west-2a
# SubnetId: subnet-0eb071cefb24ee93e

aws ec2 create-subnet \
  --vpc-id vpc-0d94dfe2aabb67a15 \
  --cidr-block 10.200.10.0/23 \
  --availability-zone us-west-2b
# SubnetId: subnet-087e211be9ed5b437
```

**Create DB subnet group:**
```bash
aws rds create-db-subnet-group \
  --db-subnet-group-name "CafeDB Subnet Group" \
  --db-subnet-group-description "DB subnet group for Cafe" \
  --subnet-ids subnet-0eb071cefb24ee93e subnet-087e211be9ed5b437 \
  --tags "Key=Name,Value=CafeDatabaseSubnetGroup"
```

### Task 2.4: Creating the Amazon RDS MariaDB instance

The lab specified engine version 10.5.13 which is no longer available in us-west-2. I queried available versions with `aws rds describe-db-engine-versions --engine mariadb` and used 10.5.29 — the latest in the same 10.5.x branch.

```bash
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
```

I polled status until `available` (status progressed: creating → backing-up → available):

```bash
aws rds describe-db-instances \
  --db-instance-identifier CafeDBInstance \
  --query "DBInstances[*].[Endpoint.Address,AvailabilityZone,PreferredBackupWindow,BackupRetentionPeriod,DBInstanceStatus]"
```

![RDS instance available](screenshots/04_rds_instance_available.png)

## Task 3: Migrating application data to the Amazon RDS instance

I connected to CafeInstance (i-0bab9bc6e23092ac4) via EC2 Instance Connect.

![CafeInstance connected](screenshots/05_cafeinstance_connected.png)

**Export the local cafe_db with mysqldump:**
```bash
mysqldump --user=root --password='Re:Start!9' \
  --databases cafe_db --add-drop-database > cafedb-backup.sql

ls -lh cafedb-backup.sql
# -rw-rw-r-- 1 ec2-user ec2-user 5.9K Mar 28 22:16 cafedb-backup.sql
```

![Backup created](screenshots/06_cafedb_backup_created.png)

**Restore to RDS:**
```bash
mysql --user=root --password='Re:Start!9' \
  --host=cafedbinstance.cc2xzhar0qoi.us-west-2.rds.amazonaws.com \
  < cafedb-backup.sql
```

**Verify the migration:**
```bash
mysql --user=root --password='Re:Start!9' \
  --host=cafedbinstance.cc2xzhar0qoi.us-west-2.rds.amazonaws.com \
  cafe_db
```
```sql
select * from product;
exit
```

![RDS data verified](screenshots/07_rds_data_verified.png)

The query returned 9 rows — Croissant, Donut, Chocolate Chip Cookie, Muffin, Strawberry Blueberry Tart, Strawberry Tart, Coffee, Hot Chocolate, Latte — confirming the full product catalogue migrated intact.

## Task 4: Configuring the website to use the Amazon RDS instance

I updated the `/cafe/dbUrl` parameter in AWS Systems Manager Parameter Store, replacing the local database hostname with `cafedbinstance.cc2xzhar0qoi.us-west-2.rds.amazonaws.com`. The café application reads this parameter at runtime so no code changes were required.

![Parameter Store updated](screenshots/08_parameter_store_updated.png)

I opened `35.93.152.199/cafe` and confirmed Order History showed the same Order 1 ($23.00, 2026-03-28) as before — the data migrated intact.

![Order History after migration](screenshots/09_order_history_after_migration.png)

## Task 5: Monitoring the Amazon RDS database

I navigated to RDS → Databases → cafedbinstance → Monitoring tab to view CloudWatch metrics. The tab showed CPU credit balance/usage, and after scrolling, DatabaseConnections, FreeStorageSpace, and others.

![RDS Monitoring tab](screenshots/10_rds_monitoring_tab.png)

I filtered the metrics view by "da" to isolate DatabaseConnections, then opened a MySQL session from the CafeInstance terminal. The graph registered the connection activity as a spike.

![DatabaseConnections metric](screenshots/11_database_connections_metric.png)

After running `exit` to close the session, refreshing the DatabaseConnections graph in CloudWatch showed the connection activity had ended.

![DatabaseConnections after exit](screenshots/12_database_connections_metric_new_request.png)

## Challenges I Had

The lab specified `--engine-version 10.5.13` for the RDS instance, but this version is no longer available in us-west-2. The command failed with `InvalidParameterCombination: Cannot find version 10.5.13 for mariadb`. I queried available versions with `aws rds describe-db-engine-versions --engine mariadb` and substituted `10.5.29` — the latest patch in the same 10.5.x branch — which succeeded.

## What I Learned

- When a DB subnet group is created for RDS, at least two subnets in different Availability Zones are required — not because both host the instance simultaneously, but because the subnet group defines the AZs where RDS can place the instance, including during a failover. Even a single-AZ deployment needs this structure to satisfy the RDS service requirement.

- The `--no-publicly-accessible` flag means RDS does not receive a public IP address. Combined with the security group rule restricting port 3306 to traffic sourced from `sg-098c59de9c16e6b2d` only, the database is completely unreachable from the internet — only the CafeInstance can open a connection.

- Parameter Store decouples configuration from code. Updating `/cafe/dbUrl` to the RDS endpoint redirected all database traffic without touching any application files. This pattern is standard for environment-specific configuration and makes migrations reversible by changing the parameter value back.

- `mysqldump` produces a portable SQL script containing all `CREATE TABLE`, `INSERT`, and `DROP DATABASE` statements needed to reproduce the database on any compatible server. The `--add-drop-database` flag ensures the target database is dropped and recreated cleanly, preventing duplicate data if the import runs more than once.

- CloudWatch sends RDS metrics automatically every minute. The DatabaseConnections metric is particularly useful for diagnosing connection pool exhaustion — a common production issue where web applications open more connections than the database instance can handle.

## Resource Names Reference

| Resource / Setting | Value |
|---|---|
| CafeInstanceURL | 35.93.152.199/cafe |
| CafeInstancePublicDNS | ec2-35-93-152-199.us-west-2.compute.amazonaws.com |
| CafeInstance ID | i-0bab9bc6e23092ac4 |
| CafeInstance Private IP | 10.200.0.73 |
| CLI Host Private IP | 10.200.0.113 |
| AccessKey | AKIA3F24OA7BV5X3T4HT |
| LabRegion | us-west-2 |
| CafeVpcID | vpc-0d94dfe2aabb67a15 |
| CafeInstanceAZ | us-west-2a |
| CafeSecurityGroupID | sg-098c59de9c16e6b2d |
| CafeDatabaseSG Group ID | sg-0774228eadec3823d |
| CafeDB Private Subnet 1 ID | subnet-0eb071cefb24ee93e (us-west-2a, 10.200.2.0/23) |
| CafeDB Private Subnet 2 ID | subnet-087e211be9ed5b437 (us-west-2b, 10.200.10.0/23) |
| DB Instance Identifier | CafeDBInstance |
| Engine Version | MariaDB 10.5.29 |
| DB Instance Class | db.t3.micro |
| Allocated Storage | 20 GB |
| DB Subnet Group Name | CafeDB Subnet Group |
| RDS Endpoint Address | cafedbinstance.cc2xzhar0qoi.us-west-2.rds.amazonaws.com |
| Preferred Backup Window | 06:23-06:53 |
| Backup Retention Period | 1 day |
| RDS Master Username | root |
| Parameter Store Key | /cafe/dbUrl |
| Local Repo Root | ~/Desktop/AWS-reStart-Journey/Labs/Databases/lab-179-migrating-to-amazon-rds |
| Screenshots Folder | ~/Desktop/AWS-reStart-Journey/Labs/Databases/lab-179-migrating-to-amazon-rds/screenshots/ |

## Commands Reference

All commands run during this lab are saved in [commands.sh](commands.sh).
