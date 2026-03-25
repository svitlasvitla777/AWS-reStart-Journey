#!/bin/bash
# Lab 185: Working with Amazon S3
# All commands in order. Replace cafe-aws777 with your actual bucket name.

# ── Task 1.2: Configure AWS CLI ────────────────────────────────────────────────
aws configure
# Enter: AccessKey, SecretKey, us-west-2, json

# ── Task 2: Create and initialise S3 bucket ────────────────────────────────────
aws s3 mb s3://cafe-aws777 --region 'us-west-2'
aws s3 sync ~/initial-images/ s3://cafe-aws777/images
aws s3 ls s3://cafe-aws777/images/ --human-readable --summarize

# ── Task 4.2: Create event notification config and apply ───────────────────────
vi s3EventNotification.json
# (paste JSON with real SNS ARN, save with :wq)

aws s3api put-bucket-notification-configuration \
  --bucket cafe-aws777 \
  --notification-configuration file://s3EventNotification.json

# ── Task 5: Reconfigure CLI as mediacouser ────────────────────────────────────
aws configure
# Enter: mediacouser Access Key ID, Secret Access Key, Enter (keep region), json

# Test: put object
aws s3api put-object \
  --bucket cafe-aws777 \
  --key images/Caramel-Delight.jpg \
  --body ~/new-images/Caramel-Delight.jpg

# Test: get object (no notification)
aws s3api get-object \
  --bucket cafe-aws777 \
  --key images/Donuts.jpg \
  Donuts.jpg

# Test: delete object
aws s3api delete-object \
  --bucket cafe-aws777 \
  --key images/Strawberry-Tarts.jpg

# Test: unauthorized ACL change (expected: AccessDenied)
aws s3api put-object-acl \
  --bucket cafe-aws777 \
  --key images/Donuts.jpg \
  --acl public-read
