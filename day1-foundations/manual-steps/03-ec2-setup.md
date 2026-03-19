# EC2 Instance Setup - Detailed Guide

## What We're Building

A compute instance that will host our Sock Shop application:
- **Instance Type**: t2.micro (Free Tier eligible)
- **OS**: Ubuntu 22.04 LTS (recommended) or Amazon Linux 2023
- **Software**: Docker + Docker Compose + Git (installed via user data)
- **Location**: Public subnet of our sockshop-vpc

## Prerequisites

- [ ] VPC and networking setup complete ([02-vpc-setup.md](./02-vpc-setup.md))
- [ ] You know your VPC ID and public subnet IDs
- [ ] Logged in as IAM admin user

## Step 1: Create a Key Pair

SSH key pairs let you securely log into your EC2 instance.

### Via Console

1. Navigate to **EC2 Console → Key Pairs** (left sidebar under "Network & Security")
2. Click **"Create key pair"**
3. Settings:
   - **Name**: `sockshop-key`
   - **Key pair type**: RSA
   - **Private key file format**: `.pem` (Mac/Linux) or `.ppk` (Windows/PuTTY)
4. Click **"Create key pair"**
5. Your browser downloads `sockshop-key.pem`

### Set Permissions

```bash
# Move to a safe location
mv ~/Downloads/sockshop-key.pem ~/.ssh/sockshop-key.pem

# Set strict permissions (required by SSH)
chmod 400 ~/.ssh/sockshop-key.pem

# Verify
ls -la ~/.ssh/sockshop-key.pem
# Should show: -r-------- (read-only for owner)
```

### Via CLI (Alternative)

```bash
aws ec2 create-key-pair \
  --key-name sockshop-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/sockshop-key.pem

chmod 400 ~/.ssh/sockshop-key.pem
```

## Step 2: Create Security Group for EC2

Security groups act as virtual firewalls for your instance.

### Via Console

1. Navigate to **EC2 Console → Security Groups**
2. Click **"Create security group"**
3. Basic details:
   - **Name**: `sockshop-ec2-sg`
   - **Description**: `Security group for Sock Shop EC2 instance`
   - **VPC**: Select `sockshop-vpc`

4. **Inbound Rules** - Click "Add rule" for each:

| Type | Port | Source | Description |
|------|------|--------|-------------|
| SSH | 22 | My IP | SSH access from your IP only |
| HTTP | 80 | 0.0.0.0/0 | HTTP from ALB |
| Custom TCP | 8079 | 0.0.0.0/0 | Sock Shop frontend (temporary, will restrict to ALB later) |

5. **Outbound Rules**: Leave default (All traffic → 0.0.0.0/0)
6. Add tag: `Key=Project, Value=SockShop`
7. Click **"Create security group"**

### Why These Specific Rules?

- **SSH (22) from My IP**: Only YOU can SSH in. If someone gets your key, they still can't connect from a different IP.
- **HTTP (80)**: The ALB will talk to your instance on port 80 (we'll set this up later).
- **8079**: Sock Shop runs on this port. We open it temporarily for testing; later we'll restrict it to the ALB only.

### Via CLI (Alternative)

```bash
# Get your VPC ID
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=sockshop-vpc" \
  --query 'Vpcs[0].VpcId' --output text)

# Create security group
SG_ID=$(aws ec2 create-security-group \
  --group-name sockshop-ec2-sg \
  --description "Security group for Sock Shop EC2 instance" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

# Get your current public IP
MY_IP=$(curl -s https://checkip.amazonaws.com)

# Add inbound rules
aws ec2 authorize-security-group-ingress --group-id $SG_ID \
  --protocol tcp --port 22 --cidr ${MY_IP}/32

aws ec2 authorize-security-group-ingress --group-id $SG_ID \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress --group-id $SG_ID \
  --protocol tcp --port 8079 --cidr 0.0.0.0/0

# Tag it
aws ec2 create-tags --resources $SG_ID \
  --tags Key=Project,Value=SockShop Key=Name,Value=sockshop-ec2-sg

echo "Security Group: $SG_ID"
```

## Step 3: Prepare User Data Script

User data is a startup script that runs when the instance first boots.

### For Ubuntu 22.04 (Recommended)

```bash
#!/bin/bash
# Day 1 - EC2 User Data Script (Ubuntu)
# This runs automatically on first boot

# Update system packages
apt-get update -y
apt-get upgrade -y

# Install Docker
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group (allows docker commands without sudo)
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install useful tools
apt-get install -y git curl wget mysql-client jq

# Log completion
echo "User data script completed at $(date)" > /tmp/user-data-complete.txt
```

### For Amazon Linux 2023

```bash
#!/bin/bash
# Day 1 - EC2 User Data Script (Amazon Linux 2023)

# Update system packages (with retry for network issues)
for i in {1..5}; do
    yum update -y && break || sleep 10
done

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install useful tools
yum install -y git curl wget mysql jq

# Log completion
echo "User data script completed at $(date)" > /tmp/user-data-complete.txt
```

## Step 4: Launch EC2 Instance

### Via Console

1. Navigate to **EC2 Console → Instances → Launch instances**
2. **Name**: `sockshop-app-server`
3. **AMI**:
   - **Ubuntu**: Search "Ubuntu" → Select "Ubuntu Server 22.04 LTS (HVM), SSD Volume Type" → 64-bit (x86)
   - **Amazon Linux**: Select "Amazon Linux 2023 AMI" → 64-bit (x86)
4. **Instance type**: `t2.micro` (look for the "Free tier eligible" label)
5. **Key pair**: Select `sockshop-key`
6. **Network settings** → Click **Edit**:
   - **VPC**: `sockshop-vpc`
   - **Subnet**: Choose a PUBLIC subnet (e.g., `sockshop-subnet-public1-us-east-1a`)
   - **Auto-assign public IP**: **Enable** (CRITICAL!)
   - **Firewall**: Select existing security group → `sockshop-ec2-sg`
7. **Configure storage**: 8 GB gp3 (default, within Free Tier)
8. **Advanced details** → Scroll to **User data**:
   - Paste the appropriate user data script from Step 3
   - Do NOT check "User data has already been base64 encoded"
9. Add tags: `Key=Project, Value=SockShop`
10. Review and click **"Launch instance"**

### Via CLI (Alternative)

```bash
# Get the latest Ubuntu 22.04 AMI ID
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text)

# Get your public subnet ID
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=*public1*" \
  --query 'Subnets[0].SubnetId' --output text)

# Launch the instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --key-name sockshop-key \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_ID \
  --associate-public-ip-address \
  --user-data file://user-data-ubuntu.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=sockshop-app-server},{Key=Project,Value=SockShop}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance launched: $INSTANCE_ID"

# Wait for it to be running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo "Instance is running!"

# Get the public IP
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Public IP: $PUBLIC_IP"
```

## Step 5: Connect via SSH

Wait 2-3 minutes for the instance to fully boot, then:

### For Ubuntu

```bash
ssh -i ~/.ssh/sockshop-key.pem ubuntu@YOUR_PUBLIC_IP
```

### For Amazon Linux

```bash
ssh -i ~/.ssh/sockshop-key.pem ec2-user@YOUR_PUBLIC_IP
```

**Accept the fingerprint** by typing `yes` when prompted.

## Step 6: Verify User Data Script

Once connected, verify everything installed correctly:

```bash
# Check user data completion
cat /tmp/user-data-complete.txt

# Check Docker
docker --version
# Expected: Docker version 24.x or later

# Check Docker Compose
docker-compose --version
# Expected: Docker Compose version v2.x

# Check Docker is running
sudo systemctl status docker
# Should show: active (running)

# Test Docker works (may need to log out/in for group permissions)
docker ps
# If "permission denied", run: newgrp docker
# Or logout and SSH back in
```

### If User Data Script Failed

Check the log:
```bash
# View the user data execution log
sudo cat /var/log/cloud-init-output.log | tail -50
```

Common reasons for failure:
- **No internet access**: Check subnet is public, auto-assign public IP is enabled, route table has IGW route
- **Package download timeout**: Wait and retry manually
- **Wrong script for OS**: Ubuntu script on Amazon Linux or vice versa

**Manual fix** (run the commands from the user data script manually):

```bash
# For Ubuntu
sudo apt-get update -y
sudo apt-get install -y docker.io git curl wget mysql-client jq
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
# Log out and back in for docker group to take effect
exit
```

## Troubleshooting

### Can't SSH: "Connection timed out"

1. Is the instance running? Check EC2 Console → Instance State
2. Does the instance have a public IP? Check EC2 Console → Public IPv4 address
3. Is port 22 open? Check security group inbound rules
4. Has your IP changed? Update security group SSH rule with current IP
5. Are you using the right key? Verify path to `.pem` file

### Can't SSH: "Permission denied (publickey)"

1. Wrong username? Ubuntu = `ubuntu`, Amazon Linux = `ec2-user`
2. Wrong key file? Verify you're using the correct `.pem` file
3. Wrong permissions on key? Run `chmod 400 ~/.ssh/sockshop-key.pem`

### Instance shows "1/2 checks passed"

- Wait 5 minutes - the system status check takes time
- If it stays at 1/2 after 10 minutes, the instance might have issues
- Try stopping and starting (not terminating) the instance

## Save Your Resource IDs

```
Key Pair Name:       sockshop-key
Security Group ID:   sg-________________
Instance ID:         i-________________
Public IP:           ___.___.___.__
```

## What You Learned

- How EC2 instances work (AMIs, instance types, key pairs)
- Security groups as stateful firewalls
- User data scripts for automated setup
- SSH key management and secure access

## Next Step

Your server is running with Docker installed. Let's deploy the Sock Shop application.

**Next**: [04-sockshop-deployment.md](./04-sockshop-deployment.md) - Deploy the Sock Shop microservices

---

**Time spent**: ~20-30 minutes (including wait for instance boot)
**Cost so far**: $0 (EC2 t2.micro is Free Tier)
**Resources created**: Key pair, security group, EC2 instance
