#!/bin/bash
# Lab 264 — Creating Networking Resources in an Amazon VPC
# All AWS resources created via AWS Management Console (no CLI commands)
# This file contains SSH and Git commands only.

# ── SSH ───────────────────────────────────────────────────────────────────────

cd ~/Downloads
chmod 400 labsuser.pem
ssh -i labsuser.pem ec2-user@44.249.193.243

# ── PING (run inside EC2 via SSH) ─────────────────────────────────────────────

ping google.com

# ── GIT ───────────────────────────────────────────────────────────────────────

cd ~/Desktop/AWS-reStart-Journey/Labs/Networking/lab-264-creating-networking-resources-vpc
git pull origin main --no-rebase
git add .
git commit -m "Add Lab 264 — Creating Networking Resources in Amazon VPC"
git push origin main
