#!/bin/bash
# EC2 User Data Script — Apache Web Server Bootstrap
# AWS re/Start Challenge Lab
# This script runs automatically on first boot of the EC2 instance.

# Update all installed packages
yum update -y

# Install Apache HTTP Server
yum install -y httpd

# Start the Apache service immediately
systemctl start httpd

# Enable Apache to start automatically on every reboot
systemctl enable httpd

# Give write permission to all users on the web root directory
# (allows ec2-user to deploy files without sudo for file creation)
chmod 777 /var/www/html

echo "Apache httpd installation complete." >> /var/log/user-data.log
