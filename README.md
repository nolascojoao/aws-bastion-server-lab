## Task 1: Creating a VPC
**1.1. Create a VPC:**
```bash
aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=Lab VPC}]"
```
**1.2. Enable DNS hostnames:**
```bash
aws ec2 modify-vpc-attribute \
  --vpc-id <vpc-id> \
  --enable-dns-hostnames "{"Value":true}"
```

---

## Task 2: Creating Subnets
**2.1. Create the public subnet:**
```bash
aws ec2 create-subnet \
  --vpc-id <vpc-id> \
  --cidr-block 10.0.0.0/24 \
  --availability-zone <availability-zone> \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Public Subnet}]"
```
**2.2. Enable auto-assign public IP:**
```bash
aws ec2 modify-subnet-attribute \
  --subnet-id <subnet-id> \
  --map-public-ip-on-launch
```

**2.3. Creating a Private Subnet:**
```bash
aws ec2 create-subnet \
  --vpc-id <vpc-id> \
  --cidr-block 10.0.2.0/23 \
  --availability-zone <availability-zone> \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=Private Subnet}]"
```

---

## Task 3: Creating an Internet Gateway
**3.1. Create an Internet Gateway:**
```bash
aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Lab IGW}]"
```
**3.2. Attach it to the VPC:**
```bash
aws ec2 attach-internet-gateway \
  --vpc-id <vpc-id> \
  --internet-gateway-id <igw-id>
```

---

## Task 4: Configuring Route Tables
**4.1. Create a public route table.:**
```bash
aws ec2 create-route-table \
  --vpc-id <vpc-id> \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Public Route Table}]"
```
**4.2. Add a route for the Internet Gateway:**
```bash
aws ec2 create-route \
  --route-table-id <route-table-id> \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id <igw-id>
```
**4.3. Associate the route table with the public subnet:**
```bash
aws ec2 associate-route-table \
  --route-table-id <route-table-id> \
  --subnet-id <subnet-id>
```
**4.4. Create a private route table:**
```bash
aws ec2 create-route-table \
  --vpc-id <vpc-id> \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Private Route Table}]"
```
**4.5. Associate the route table with the private subnet:**
```bash
aws ec2 associate-route-table \
  --route-table-id <route-table-id> \
  --subnet-id <subnet-id>
```

---

## Task 5: Launching a Bastion Server
**5.1. Create a Security Group to allow SSH access:**
```bash
aws ec2 create-security-group \
  --group-name BastionSG \
  --description "Secrutiy Group for Bastion Server" \
  --vpc-id <vpc-id>
```
**5.2. Authorize SSH access (port 22) in the security group:**
```bash
aws ec2 authorize-security-group-ingress \
  --group-id <security-group-id> \
  --protocol tcp \
  --port 22 \
  --cidr <your-machine-public-ip-address>/32
```  
**5.3. Launch an EC2 instance (Bastion Server) in the public subnet:**
```bash
aws ec2 run-instances \
  --image-id <ami-id> \
  --instance-type t2.micro \
  --key-name <key-name> \
  --subnet-id <subnet-id> \
  --security-group-ids <security-group-id> \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Bastion Server}]" \
```
---

⚠️ **Attention:** If you don't have a key pair learn how to create one by following this [guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html)

---

  - Alternatively to quickly create a Key Pair use this command before launching the EC2 instance:
```bash
aws ec2 create-key-pair \
--key-name <new-key-name> \
--query 'KeyMaterial' --output text > <new-key-name>.pem
chmod 400 <new-key-name>.pem
```

---

## Task 6: Creating a NAT Gateway
**6.1. Create a NAT Gateway in the public subnet:**
```bash
aws ec2 create-nat-gateway \
  --subnet-id <subnet-id> \
  --allocation-id <eip-alloc-id> \
  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=Lab NAT Gateway}]"
```
**6.2. Add a route for the NAT Gateway in the private route table:**
```bash
aws ec2 create-route \
  --route-table-id <route-table-id> \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id <nat-gateway-id>
```

---

## Task 7: Logging into Bastion Server and Creating EC2 in Private Subnet
**7.1. SSH into the Bastion Server:**
```bash
ssh -i <key-name>.pem ec2-user@<bastion-public-ip>
```

**7.2. Create a Security Group for the EC2 in the private subnet:**
```bash
aws ec2 create-security-group \
  --group-name PrivateEC2SG \
  --description "Security Group for EC2 in Private Subnet" \
  --vpc-id <vpc-id>
```

**7.3. Authorize SSH access for the subnet 10.0.0.0/16:**
```bash
aws ec2 authorize-security-group-ingress \
  --group-id <security-group-id> \
  --protocol tcp \
  --port 22 \
  --cidr 10.0.0.0/16
```

**7.4. Launch the EC2 instance in the private subnet:**
  - **AMI Suggestion:** `ami-0ebfd941bbafe70c6`. [Find an AMI](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html)
```bash
aws ec2 run-instances \
  --image-id <ami-id> \
  --instance-type t2.micro \
  --key-name <key-name> \
  --subnet-id <private-subnet-id> \
  --security-group-ids <security-group-id> \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Private EC2}]"
```
---

⚠️ **Attention:** For better security create a new Key Pair for the EC2 in the private subnet. Avoid reusing the Bastion Server Key Pair! 🔑 
  - Refer to step 5.3 for instructions on creating a Key Pair.

---

**7.5. SSH from Bastion Server into the EC2 instance in the private subnet:**
```bash
ssh -i <key-name>.pem ec2-user@<private-ec2-private-ip>
```

**7.6. Perform a ping test to the NAT Gateway**
```bash
ping <nat-gateway-ip>
```
