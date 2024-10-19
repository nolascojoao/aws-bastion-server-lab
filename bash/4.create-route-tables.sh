#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Variables
VPC_NAME="Lab VPC"  # Name of the VPC
IGW_NAME="Lab IGW"  # Name of the Internet Gateway
PUBLIC_SUBNET_NAME="Public Subnet"  # Name of the Public Subnet
PRIVATE_SUBNET_NAME="Private Subnet"  # Name of the Private Subnet

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

# 2. Get the Internet Gateway ID by name
IGW_ID=$(aws ec2 describe-internet-gateways \
  --filters "Name=tag:Name,Values=$IGW_NAME" \
  --query "InternetGateways[0].InternetGatewayId" \
  --output text)

# Check if IGW_ID is empty
if [ -z "$IGW_ID" ]; then
  echo "Internet Gateway with name '$IGW_NAME' not found."
  exit 1
fi

# 3. Get the Public Subnet ID by name
PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=$PUBLIC_SUBNET_NAME" \
  --query "Subnets[0].SubnetId" \
  --output text)

# Check if PUBLIC_SUBNET_ID is empty
if [ -z "$PUBLIC_SUBNET_ID" ]; then
  echo "Public Subnet with name '$PUBLIC_SUBNET_NAME' not found."
  exit 1
fi

# 4. Get the Private Subnet ID by name
PRIVATE_SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=$PRIVATE_SUBNET_NAME" \
  --query "Subnets[0].SubnetId" \
  --output text)

# Check if PRIVATE_SUBNET_ID is empty
if [ -z "$PRIVATE_SUBNET_ID" ]; then
  echo "Private Subnet with name '$PRIVATE_SUBNET_NAME' not found."
  exit 1
fi

# 4.1. Create a public route table
PUBLIC_ROUTE_TABLE_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Public Route Table}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)

echo "Public Route Table created with ID: $PUBLIC_ROUTE_TABLE_ID"

# 4.2. Add a route for the Internet Gateway
aws ec2 create-route \
  --route-table-id $PUBLIC_ROUTE_TABLE_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

echo "Route to Internet Gateway added to Public Route Table"

# 4.3. Associate the route table with the public subnet
aws ec2 associate-route-table \
  --route-table-id $PUBLIC_ROUTE_TABLE_ID \
  --subnet-id $PUBLIC_SUBNET_ID

echo "Public Route Table associated with Public Subnet"

# 4.4. Create a private route table
PRIVATE_ROUTE_TABLE_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Private Route Table}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)

echo "Private Route Table created with ID: $PRIVATE_ROUTE_TABLE_ID"

# 4.5. Associate the route table with the private subnet
aws ec2 associate-route-table \
  --route-table-id $PRIVATE_ROUTE_TABLE_ID \
  --subnet-id $PRIVATE_SUBNET_ID

echo "Private Route Table associated with Private Subnet"
