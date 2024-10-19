#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Variables
VPC_NAME="Lab VPC"  # Name of the VPC

# 1. Get the VPC ID by name
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=$VPC_NAME" \
  --query "Vpcs[0].VpcId" \
  --output text)

# Check if VPC_ID is empty
if [ -z "$VPC_ID" ]; then
  echo "VPC with name '$VPC_NAME' not found."
  exit 1
fi

# 3.1. Create an Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Lab IGW}]" \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

echo "Internet Gateway created with ID: $IGW_ID"

# 3.2. Attach the Internet Gateway to the VPC
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID

echo "Internet Gateway attached to VPC: $VPC_ID"
