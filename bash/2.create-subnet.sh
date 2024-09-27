#!/bin/bash

# Variables
VPC_ID="<vpc-id>"           # Replace with your VPC ID
AVAILABILITY_ZONE="<availability-zone>"  # Replace with your Availability Zone

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
aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/23 \
  --availability-zone $AVAILABILITY_ZONE \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Private Subnet}]"

echo "Private Subnet created"
