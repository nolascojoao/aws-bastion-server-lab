#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Variables
VPC_NAME="Lab VPC"  # Name of the VPC
PUBLIC_SUBNET_NAME="Public Subnet"  # Name of the Public Subnet
KEY_NAME="my-key"  # Replace with the name of your existing key pair
AMI_ID="ami-0ebfd941bbafe70c6"  # Keep the existing AMI ID

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

# 3. Get the public IP address of the machine running the script
MY_PUBLIC_IP=$(curl -s https://ipinfo.io/ip)

# Check if MY_PUBLIC_IP is retrieved
if [ -z "$MY_PUBLIC_IP" ]; then
  echo "Unable to retrieve the public IPv4 address."
  exit 1
fi

# 5.1. Create a Security Group to allow SSH access
BASTION_SG_ID=$(aws ec2 create-security-group \
  --group-name BastionSG \
  --description "Security Group for Bastion Server" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

echo "Security Group created with ID: $BASTION_SG_ID"

# 5.2. Authorize SSH access (port 22) in the security group
aws ec2 authorize-security-group-ingress \
  --group-id $BASTION_SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr $MY_PUBLIC_IP/32

echo "SSH access authorized for Security Group: $BASTION_SG_ID"

# 5.3. Create a key pair and save it to a .pem file (if it does not exist)
if [ ! -f "$KEY_NAME.pem" ]; then
  aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --query 'KeyMaterial' \
    --output text > $KEY_NAME.pem

  echo "Key pair $KEY_NAME created and saved as $KEY_NAME.pem"

  # Change permissions for the key file
  chmod 400 $KEY_NAME.pem
  echo "Permissions changed for key file $KEY_NAME.pem"
else
  echo "Key pair $KEY_NAME already exists. Using existing key."
fi

# 5.4. Launch an EC2 instance (Bastion Server) in the public subnet
BASTION_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --key-name $KEY_NAME \
  --subnet-id $PUBLIC_SUBNET_ID \
  --security-group-ids $BASTION_SG_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Bastion Server}]" \
  --associate-public-ip-address \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Bastion Server launched with Instance ID: $BASTION_INSTANCE_ID"

# 5.5. Retrieve the public IP address of the Bastion Server
BASTION_PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $BASTION_INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# Check if BASTION_PUBLIC_IP is empty
if [ -z "$BASTION_PUBLIC_IP" ]; then
  echo "Bastion Server does not have a public IP address yet."
else
  echo "Bastion Server's public IP address: $BASTION_PUBLIC_IP"
fi
