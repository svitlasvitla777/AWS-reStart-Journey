#!/bin/bash
# Lab 184 — Amazon S3 Challenge Lab
# All commands in order of execution

# ─── Task 2: Configure AWS CLI ───────────────────────────────────────────────
aws configure
# Prompts: AccessKey, SecretKey, region=us-west-2, output=json

aws s3 ls  # Verify CLI works (empty output expected)

# ─── Task 3.1: Create S3 Bucket ─────────────────────────────────────────────
aws s3 mb s3://aws-wonders --region us-west-2

# ─── Task 3.2: Upload Object ─────────────────────────────────────────────────
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<body>
<h1>Lab 184 - Amazon S3</h1>
<p>This object is hosted in S3.</p>
</body>
</html>
EOF

aws s3 cp index.html s3://aws-wonders/index.html

# ─── Task 3.4: Make Object Public ────────────────────────────────────────────
# Step 1: Disable Block Public Access
aws s3api put-public-access-block \
  --bucket aws-wonders \
  --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Step 2: Create bucket policy
cat > bucket-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::aws-wonders/*"
    }
  ]
}
EOF

# Step 3: Apply bucket policy
aws s3api put-bucket-policy \
  --bucket aws-wonders \
  --policy file://bucket-policy.json

# ─── Task 3.6: List Bucket Contents ─────────────────────────────────────────
aws s3 ls s3://aws-wonders
aws s3 ls s3://aws-wonders --recursive --human-readable

# ─── Git: Push to GitHub ─────────────────────────────────────────────────────
git add screenshots/ README.md commands.sh
git commit -m "Lab 184: Amazon S3 challenge lab completed"
git push origin main
