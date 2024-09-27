#!/bin/bash

# Variables
VPC_ID="<vpc-id>"                   # Replace with your VPC ID
MY_PUBLIC_IP="<your-machine-public-ip-address>"  # Replace with your machine's public IP address
PUBLIC_SUBNET_ID="<public-subnet-id>"            # Replace with your Public Subnet ID
AMI_ID="ami-0ebfd941bbafe70c6"      # Replace with your preferred AMI ID (this is a suggestion)
KEY_NAME="<new-key-name>"           # Replace with the name of your new key pair

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

# 5.3. Create a key pair and save it to a .pem file
aws ec2 create-key-pair \
  --key-name $KEY_NAME \
  --query 'KeyMaterial' \
  --output text > $KEY_NAME.pem

echo "Key pair $KEY_NAME created and saved as $KEY_NAME.pem"

# Change permissions for the key file
chmod 400 $KEY_NAME.pem
echo "Permissions changed for key file $KEY_NAME.pem"

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
