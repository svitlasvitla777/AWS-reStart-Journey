#!/bin/bash
# Lab 266 — Troubleshooting a Network Issue
# AWS re/Start Programme
# Region: us-west-2 | Instance: 44.255.199.108 (ip-10-0-10-67)

# ── Task 1: SSH into EC2 instance ─────────────────────────────────────────────
cd ~/Downloads
chmod 400 labsuser.pem
ssh -i labsuser.pem ec2-user@44.255.199.108

# ── Task 2: Install httpd ─────────────────────────────────────────────────────
sudo systemctl status httpd.service
sudo systemctl start httpd.service
sudo systemctl status httpd.service

# ── Git ───────────────────────────────────────────────────────────────────────
cd ~/Desktop/AWS-reStart-Journey
git pull origin main --no-rebase
git add Labs/Networking/lab-266-troubleshooting-network/
git commit -m "Add Lab 266 – Troubleshooting a Network Issue"
git push origin main
