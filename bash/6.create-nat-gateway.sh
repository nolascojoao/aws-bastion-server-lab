#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Variables
VPC_NAME="Lab VPC"  # Name of the VPC
PUBLIC_SUBNET_NAME="Public Subnet"  # Name of the Public Subnet
PRIVATE_ROUTE_TABLE_NAME="Private Route Table"  # Name of the Private Route Table

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

# 2. Get the Public Subnet ID by name
PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=$PUBLIC_SUBNET_NAME" \
  --query "Subnets[0].SubnetId" \
  --output text)

# Check if PUBLIC_SUBNET_ID is empty
if [ -z "$PUBLIC_SUBNET_ID" ]; then
  echo "Public Subnet with name '$PUBLIC_SUBNET_NAME' not found."
  exit 1
fi

# 3. Get the Private Route Table ID by name
PRIVATE_ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=$PRIVATE_ROUTE_TABLE_NAME" \
  --query "RouteTables[0].RouteTableId" \
  --output text)

# Check if PRIVATE_ROUTE_TABLE_ID is empty
if [ -z "$PRIVATE_ROUTE_TABLE_ID" ]; then
  echo "Private Route Table with name '$PRIVATE_ROUTE_TABLE_NAME' not found."
  exit 1
fi

# 6.1. Allocate an Elastic IP to your account
EIP_ALLOC_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --query 'AllocationId' \
  --output text)

if [ -z "$EIP_ALLOC_ID" ]; then
  echo "Failed to allocate Elastic IP. Exiting."
  exit 1
else
  echo "Elastic IP allocated with Allocation ID: $EIP_ALLOC_ID"
fi

# 6.2. Create a NAT Gateway in the public subnet
NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_ID \
  --allocation-id $EIP_ALLOC_ID \
  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Lab NAT Gateway}]" \
  --query 'NatGateway.NatGatewayId' \
  --output text)

if [ -z "$NAT_GW_ID" ]; then
  echo "Failed to create NAT Gateway. Exiting."
  exit 1
else
  echo "NAT Gateway created with ID: $NAT_GW_ID"
fi

# Wait until NAT Gateway is available before proceeding
echo "Waiting for NAT Gateway..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID
echo "NAT Gateway is now available."

# 6.3. Add a route for the NAT Gateway in the private route table
aws ec2 create-route \
  --route-table-id $PRIVATE_ROUTE_TABLE_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GW_ID

if [ $? -ne 0 ]; then
  echo "Failed to create a route for NAT Gateway. Exiting."
  exit 1
else
  echo "Route for NAT Gateway added to Private Route Table."
fi
