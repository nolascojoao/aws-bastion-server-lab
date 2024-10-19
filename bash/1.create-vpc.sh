#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Create a VPC with a specified CIDR block and tags
aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=Lab VPC}]"

# Notification of success
if [ $? -eq 0 ]; then
  echo "VPC 'Lab VPC' created successfully."
else
  echo "Failed to create VPC."
fi
