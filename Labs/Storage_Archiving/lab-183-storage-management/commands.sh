#!/bin/bash
# Lab 183: Managing Storage — Command Reference
# S3 bucket:     lab183-storage
# S3 prefix:     lab183-files/
# Snapshot desc: lab183-processor-snapshot
# IAM role:      S3BucketAccess
# Volume ID:     vol-0b222992521185d43
# Instance ID:   i-0f6b0a528d9335b6e
# Replace snap-00006882d3afb4b3f and <VERSION-ID> with values from your lab session.

# ════════════════════════════════════════════════════════════
# TASK 1.1 — Create S3 Bucket (done in console)
# Bucket name: lab183-storage

# TASK 1.2 — Attach IAM Role (done in console)
# Role: S3BucketAccess → Processor instance

# ════════════════════════════════════════════════════════════
# TASK 2.1 — Connect to Command Host (done in console via EC2 Instance Connect)

# ════════════════════════════════════════════════════════════
# TASK 2.2 — Taking an Initial Snapshot

# Get EBS Volume ID
aws ec2 describe-instances \
  --filter 'Name=tag:Name,Values=Processor' \
  --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.{VolumeId:VolumeId}'

# Get Processor Instance ID
aws ec2 describe-instances \
  --filters 'Name=tag:Name,Values=Processor' \
  --query 'Reservations[0].Instances[0].InstanceId'

# Stop the Processor
aws ec2 stop-instances --instance-ids i-0f6b0a528d9335b6e
aws ec2 wait instance-stopped --instance-id i-0f6b0a528d9335b6e

# Create the snapshot
aws ec2 create-snapshot \
  --volume-id vol-0b222992521185d43 \
  --description "lab183-processor-snapshot"

# Wait for it to complete
aws ec2 wait snapshot-completed --snapshot-id snap-00006882d3afb4b3f

# Restart the Processor
aws ec2 start-instances --instance-ids i-0f6b0a528d9335b6e

# ════════════════════════════════════════════════════════════
# TASK 2.3 — Scheduling Subsequent Snapshots

# Create cron job file
echo "* * * * *  aws ec2 create-snapshot --volume-id vol-0b222992521185d43 2>&1 >> /tmp/cronlog" > cronjob

# Register the cron job
crontab cronjob

# Verify it is registered
crontab -l

# Check snapshots are being created (re-run after a few minutes)
aws ec2 describe-snapshots \
  --filters "Name=volume-id,Values=vol-0b222992521185d43" \
  --query 'Snapshots[*].{ID:SnapshotId,State:State,Time:StartTime}' \
  --output table

# ════════════════════════════════════════════════════════════
# TASK 2.4 — Retaining the Last Two Snapshots

# Stop the cron job
crontab -r

# Check snapshot count before cleanup
aws ec2 describe-snapshots \
  --filters "Name=volume-id,Values=vol-0b222992521185d43" \
  --query 'Snapshots[*].SnapshotId'

# Run the cleanup script
python3.8 snapshotter_v2.py

# Verify only two snapshots remain
aws ec2 describe-snapshots \
  --filters "Name=volume-id,Values=vol-0b222992521185d43" \
  --query 'Snapshots[*].SnapshotId'

# ════════════════════════════════════════════════════════════
# TASK 3.1 — Download and Unzip Sample Files (run on Processor)

wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-100-RSJAWS-3-124627/183-lab-JAWS-managing-storage/s3/files.zip
unzip files.zip
ls files

# ════════════════════════════════════════════════════════════
# TASK 3.2 — Syncing Files (run on Processor)

# Enable versioning — MUST be done before the first sync
aws s3api put-bucket-versioning \
  --bucket lab183-storage \
  --versioning-configuration Status=Enabled

# Sync files to S3
aws s3 sync files s3://lab183-storage/lab183-files/

# Confirm all three files are in S3
aws s3 ls s3://lab183-storage/lab183-files/

# Delete a local file
rm files/file1.txt

# Sync with --delete to mirror the deletion to S3
aws s3 sync files s3://lab183-storage/lab183-files/ --delete

# Verify file1.txt is gone from S3
aws s3 ls s3://lab183-storage/lab183-files/

# List versions to find the deleted file
# Copy the VersionId from the Versions block — NOT from DeleteMarkers
aws s3api list-object-versions \
  --bucket lab183-storage \
  --prefix lab183-files/file1.txt

# Download the previous version
aws s3api get-object \
  --bucket lab183-storage \
  --key lab183-files/file1.txt \
  --version-id <VERSION-ID> \
  files/file1.txt

# Verify all three files are restored locally
ls files

# Re-sync to push restored file back to S3
aws s3 sync files s3://lab183-storage/lab183-files/

# Confirm all three files are back in S3
aws s3 ls s3://lab183-storage/lab183-files/
