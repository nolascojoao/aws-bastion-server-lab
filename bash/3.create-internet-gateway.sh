#!/bin/bash

# Variables
VPC_ID="<vpc-id>"  # Replace with your VPC ID

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
