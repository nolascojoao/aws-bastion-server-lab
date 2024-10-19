#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Variables
VPC_NAME="Lab VPC"  # Name of the VPC
AVAILABILITY_ZONE="us-east-1a"  # Set to your desired Availability Zone

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

# 2.1. Create the public subnet
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.0.0/24 \
  --availability-zone $AVAILABILITY_ZONE \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Public Subnet}]" \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Public Subnet created with ID: $PUBLIC_SUBNET_ID"

# 2.2. Enable auto-assign public IP for the public subnet
aws ec2 modify-subnet-attribute \
  --subnet-id $PUBLIC_SUBNET_ID \
  --map-public-ip-on-launch

echo "Auto-assign public IP enabled for Public Subnet"

# 2.3. Create the private subnet
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/23 \
  --availability-zone $AVAILABILITY_ZONE \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Private Subnet}]" \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Private Subnet created with ID: $PRIVATE_SUBNET_ID"
