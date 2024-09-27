#!/bin/bash

# Variables
PUBLIC_SUBNET_ID="<public-subnet-id>"     # Replace with your Public Subnet ID
PRIVATE_ROUTE_TABLE_ID="<private-route-table-id>" # Replace with your Private Route Table ID
VPC_ID="<vpc-id>"  # Replace with your VPC ID

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
