#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Variables (replace these with actual IDs)
INSTANCE_ID="instance-id"                					# EC2 Instance ID
SECURITY_GROUP_ID="security-group-id"    					# Security Group ID
NAT_GW_ID="nat-gateway-id"               					# NAT Gateway ID
PUBLIC_ROUTE_TABLE_ID="public-route-table-id"   			# Public Route Table ID
PRIVATE_ROUTE_TABLE_ID="private-route-table-id" 			# Private Route Table ID
VPC_ID="vpc-id"                          					# VPC ID
IGW_ID="igw-id"                          					# Internet Gateway ID
PUBLIC_SUBNET_ID="public-subnet-id"      					# Public Subnet ID
PRIVATE_SUBNET_ID="private-subnet-id"    					# Private Subnet ID
EIP_ALLOC_ID="eip-alloc-id"            						# Elastic IP Allocation ID

# 8.1. Terminate EC2 Instances
echo "Deleting EC2 Instance: $INSTANCE_ID"
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
echo "Terminated EC2 Instance: $INSTANCE_ID"

# Wait for the instance to be terminated
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
echo "EC2 Instance $INSTANCE_ID has been terminated."

# 8.2. Delete the NAT Gateway
echo "Deleting NAT Gateway: $NAT_GW_ID"
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_ID
echo "Deleted NAT Gateway: $NAT_GW_ID"

# Wait for the NAT Gateway to be deleted
aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_GW_ID
echo "NAT Gateway $NAT_GW_ID has been deleted."

# 8.3. Delete Security Groups
echo "Deleting Security Group: $SECURITY_GROUP_ID"
aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID
echo "Deleted Security Group: $SECURITY_GROUP_ID"

# 8.4. Detach and Delete the Internet Gateway
echo "Detaching Internet Gateway: $IGW_ID from VPC: $VPC_ID"
aws ec2 detach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
echo "Detached Internet Gateway: $IGW_ID from VPC: $VPC_ID"
echo "Deleting Internet Gateway: $IGW_ID"
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
echo "Deleted Internet Gateway: $IGW_ID"

# 8.5. Delete Subnets (both public and private)
echo "Deleting Public Subnet: $PUBLIC_SUBNET_ID"
aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_ID
echo "Deleted Public Subnet: $PUBLIC_SUBNET_ID"

echo "Deleting Private Subnet: $PRIVATE_SUBNET_ID"
aws ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_ID
echo "Deleted Private Subnet: $PRIVATE_SUBNET_ID"

# 8.6. Delete Route Tables (both public and private)
echo "Deleting Public Route Table: $PUBLIC_ROUTE_TABLE_ID"
aws ec2 delete-route-table --route-table-id $PUBLIC_ROUTE_TABLE_ID
echo "Deleted Public Route Table: $PUBLIC_ROUTE_TABLE_ID"

echo "Deleting Private Route Table: $PRIVATE_ROUTE_TABLE_ID"
aws ec2 delete-route-table --route-table-id $PRIVATE_ROUTE_TABLE_ID
echo "Deleted Private Route Table: $PRIVATE_ROUTE_TABLE_ID"

# 8.7. Delete the VPC
echo "Deleting VPC: $VPC_ID"
aws ec2 delete-vpc --vpc-id $VPC_ID
echo "Deleted VPC: $VPC_ID"

# 8.8. Release Elastic IP
echo "Releasing Elastic IP with Allocation ID: $EIP_ALLOC_ID"
aws ec2 release-address --allocation-id $EIP_ALLOC_ID
echo "Released Elastic IP with Allocation ID: $EIP_ALLOC_ID"

echo "All resources have been deleted successfully."
