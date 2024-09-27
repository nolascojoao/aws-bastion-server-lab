#!/bin/bash

# Variables
VPC_ID="<vpc-id>"  # Replace with your VPC ID
IGW_ID="<igw-id>"  # Replace with your Internet Gateway ID
PUBLIC_SUBNET_ID="<public-subnet-id>"  # Replace with your Public Subnet ID
PRIVATE_SUBNET_ID="<private-subnet-id>"  # Replace with your Private Subnet ID

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
