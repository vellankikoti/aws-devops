#!/bin/bash

###############################################################################
# Day 1 Automated Setup Script
#
# This script automates the creation of Day 1 infrastructure via AWS CLI.
# USE THIS ONLY AFTER you've completed Day 1 manually at least once!
#
# The purpose is to quickly recreate the infrastructure if you cleaned up
# yesterday and want to continue learning, or to verify your manual work.
#
# Author: Koti
# Cost: ~$0.50/day (ALB only, everything else is Free Tier)
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_TAG="SockShop"
VPC_CIDR="10.0.0.0/16"

print_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

###############################################################################
# Pre-flight Checks
###############################################################################

preflight_check() {
    print_header "Pre-flight Checks"

    # Check AWS CLI
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS CLI not configured. Run 'aws configure' first."
        exit 1
    fi
    print_success "AWS CLI configured"

    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo "  Account: $ACCOUNT_ID"
    echo "  Region: $AWS_REGION"

    # Check for existing resources
    EXISTING_VPC=$(aws ec2 describe-vpcs \
        --region "$AWS_REGION" \
        --filters "Name=tag:Name,Values=sockshop-vpc" \
        --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "None")

    if [ "$EXISTING_VPC" != "None" ] && [ -n "$EXISTING_VPC" ]; then
        print_error "VPC 'sockshop-vpc' already exists ($EXISTING_VPC)."
        echo "  Run ./cleanup-day1.sh first, or use existing resources."
        exit 1
    fi
    print_success "No conflicting resources found"

    echo ""
    echo -e "${YELLOW}This script will create:${NC}"
    echo "  - VPC with 4 subnets (2 public, 2 private)"
    echo "  - Internet Gateway"
    echo "  - EC2 instance (t2.micro - Free Tier)"
    echo "  - RDS MySQL (db.t3.micro - Free Tier)"
    echo "  - Application Load Balancer (~\$0.50/day)"
    echo "  - Security groups, key pair, CloudWatch alarms"
    echo ""
    echo -e "${RED}Estimated cost: ~\$0.50/day (ALB only)${NC}"
    echo ""
    read -p "Continue? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo "Cancelled."
        exit 0
    fi
}

###############################################################################
# VPC Setup
###############################################################################

create_vpc() {
    print_header "Step 1: Creating VPC & Networking"

    # Create VPC
    VPC_ID=$(aws ec2 create-vpc \
        --region "$AWS_REGION" \
        --cidr-block "$VPC_CIDR" \
        --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=sockshop-vpc},{Key=Project,Value=$PROJECT_TAG}]" \
        --query 'Vpc.VpcId' --output text)
    print_success "VPC created: $VPC_ID"

    # Enable DNS hostnames
    aws ec2 modify-vpc-attribute --region "$AWS_REGION" \
        --vpc-id "$VPC_ID" --enable-dns-hostnames '{"Value":true}'
    aws ec2 modify-vpc-attribute --region "$AWS_REGION" \
        --vpc-id "$VPC_ID" --enable-dns-support '{"Value":true}'

    # Get AZs
    AZ1=$(aws ec2 describe-availability-zones --region "$AWS_REGION" \
        --query 'AvailabilityZones[0].ZoneName' --output text)
    AZ2=$(aws ec2 describe-availability-zones --region "$AWS_REGION" \
        --query 'AvailabilityZones[1].ZoneName' --output text)

    # Create Internet Gateway
    IGW_ID=$(aws ec2 create-internet-gateway --region "$AWS_REGION" \
        --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=sockshop-igw},{Key=Project,Value=$PROJECT_TAG}]" \
        --query 'InternetGateway.InternetGatewayId' --output text)
    aws ec2 attach-internet-gateway --region "$AWS_REGION" \
        --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
    print_success "Internet Gateway: $IGW_ID"

    # Create subnets
    PUB_SUBNET_1=$(aws ec2 create-subnet --region "$AWS_REGION" \
        --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/24 --availability-zone "$AZ1" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=sockshop-public-${AZ1}},{Key=Project,Value=$PROJECT_TAG}]" \
        --query 'Subnet.SubnetId' --output text)

    PUB_SUBNET_2=$(aws ec2 create-subnet --region "$AWS_REGION" \
        --vpc-id "$VPC_ID" --cidr-block 10.0.2.0/24 --availability-zone "$AZ2" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=sockshop-public-${AZ2}},{Key=Project,Value=$PROJECT_TAG}]" \
        --query 'Subnet.SubnetId' --output text)

    PRIV_SUBNET_1=$(aws ec2 create-subnet --region "$AWS_REGION" \
        --vpc-id "$VPC_ID" --cidr-block 10.0.3.0/24 --availability-zone "$AZ1" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=sockshop-private-${AZ1}},{Key=Project,Value=$PROJECT_TAG}]" \
        --query 'Subnet.SubnetId' --output text)

    PRIV_SUBNET_2=$(aws ec2 create-subnet --region "$AWS_REGION" \
        --vpc-id "$VPC_ID" --cidr-block 10.0.4.0/24 --availability-zone "$AZ2" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=sockshop-private-${AZ2}},{Key=Project,Value=$PROJECT_TAG}]" \
        --query 'Subnet.SubnetId' --output text)

    print_success "Subnets: $PUB_SUBNET_1, $PUB_SUBNET_2 (public), $PRIV_SUBNET_1, $PRIV_SUBNET_2 (private)"

    # Enable auto-assign public IP on public subnets
    aws ec2 modify-subnet-attribute --region "$AWS_REGION" \
        --subnet-id "$PUB_SUBNET_1" --map-public-ip-on-launch
    aws ec2 modify-subnet-attribute --region "$AWS_REGION" \
        --subnet-id "$PUB_SUBNET_2" --map-public-ip-on-launch

    # Create public route table
    PUB_RT=$(aws ec2 create-route-table --region "$AWS_REGION" \
        --vpc-id "$VPC_ID" \
        --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=sockshop-public-rt},{Key=Project,Value=$PROJECT_TAG}]" \
        --query 'RouteTable.RouteTableId' --output text)

    aws ec2 create-route --region "$AWS_REGION" \
        --route-table-id "$PUB_RT" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" >/dev/null
    aws ec2 associate-route-table --region "$AWS_REGION" \
        --route-table-id "$PUB_RT" --subnet-id "$PUB_SUBNET_1" >/dev/null
    aws ec2 associate-route-table --region "$AWS_REGION" \
        --route-table-id "$PUB_RT" --subnet-id "$PUB_SUBNET_2" >/dev/null

    print_success "Route tables configured"
}

###############################################################################
# Security Groups
###############################################################################

create_security_groups() {
    print_header "Step 2: Creating Security Groups"

    # EC2 Security Group
    EC2_SG=$(aws ec2 create-security-group --region "$AWS_REGION" \
        --group-name sockshop-ec2-sg \
        --description "Security group for Sock Shop EC2 instance" \
        --vpc-id "$VPC_ID" \
        --query 'GroupId' --output text)

    MY_IP=$(curl -s https://checkip.amazonaws.com 2>/dev/null || echo "0.0.0.0")

    aws ec2 authorize-security-group-ingress --region "$AWS_REGION" \
        --group-id "$EC2_SG" --protocol tcp --port 22 --cidr "${MY_IP}/32" >/dev/null
    aws ec2 authorize-security-group-ingress --region "$AWS_REGION" \
        --group-id "$EC2_SG" --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null
    aws ec2 authorize-security-group-ingress --region "$AWS_REGION" \
        --group-id "$EC2_SG" --protocol tcp --port 8079 --cidr 0.0.0.0/0 >/dev/null

    aws ec2 create-tags --region "$AWS_REGION" --resources "$EC2_SG" \
        --tags Key=Name,Value=sockshop-ec2-sg Key=Project,Value=$PROJECT_TAG
    print_success "EC2 Security Group: $EC2_SG (SSH from $MY_IP)"

    # RDS Security Group
    RDS_SG=$(aws ec2 create-security-group --region "$AWS_REGION" \
        --group-name sockshop-rds-sg \
        --description "Security group for Sock Shop RDS database" \
        --vpc-id "$VPC_ID" \
        --query 'GroupId' --output text)

    aws ec2 authorize-security-group-ingress --region "$AWS_REGION" \
        --group-id "$RDS_SG" --protocol tcp --port 3306 --source-group "$EC2_SG" >/dev/null

    aws ec2 create-tags --region "$AWS_REGION" --resources "$RDS_SG" \
        --tags Key=Name,Value=sockshop-rds-sg Key=Project,Value=$PROJECT_TAG
    print_success "RDS Security Group: $RDS_SG"

    # ALB Security Group
    ALB_SG=$(aws ec2 create-security-group --region "$AWS_REGION" \
        --group-name sockshop-alb-sg \
        --description "Security group for Sock Shop ALB" \
        --vpc-id "$VPC_ID" \
        --query 'GroupId' --output text)

    aws ec2 authorize-security-group-ingress --region "$AWS_REGION" \
        --group-id "$ALB_SG" --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null

    aws ec2 create-tags --region "$AWS_REGION" --resources "$ALB_SG" \
        --tags Key=Name,Value=sockshop-alb-sg Key=Project,Value=$PROJECT_TAG
    print_success "ALB Security Group: $ALB_SG"
}

###############################################################################
# EC2 Instance
###############################################################################

create_ec2() {
    print_header "Step 3: Launching EC2 Instance"

    # Check for existing key pair
    if aws ec2 describe-key-pairs --region "$AWS_REGION" --key-names sockshop-key >/dev/null 2>&1; then
        print_info "Key pair 'sockshop-key' already exists, reusing it"
    else
        aws ec2 create-key-pair --region "$AWS_REGION" \
            --key-name sockshop-key \
            --query 'KeyMaterial' --output text > ~/.ssh/sockshop-key.pem
        chmod 400 ~/.ssh/sockshop-key.pem
        print_success "Key pair created: ~/.ssh/sockshop-key.pem"
    fi

    # Get latest Ubuntu 22.04 AMI
    AMI_ID=$(aws ec2 describe-images --region "$AWS_REGION" \
        --owners 099720109477 \
        --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
                  "Name=state,Values=available" \
        --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
        --output text)
    print_info "Using AMI: $AMI_ID (Ubuntu 22.04)"

    # User data script
    USER_DATA=$(cat << 'USERDATA'
#!/bin/bash
apt-get update -y
apt-get upgrade -y
apt-get install -y docker.io git curl wget mysql-client jq
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
# Clone and deploy Sock Shop
cd /home/ubuntu
git clone https://github.com/microservices-demo/microservices-demo.git
cd microservices-demo/deploy/docker-compose
docker-compose up -d
echo "Setup complete at $(date)" > /tmp/user-data-complete.txt
USERDATA
)

    INSTANCE_ID=$(aws ec2 run-instances --region "$AWS_REGION" \
        --image-id "$AMI_ID" \
        --instance-type t2.micro \
        --key-name sockshop-key \
        --security-group-ids "$EC2_SG" \
        --subnet-id "$PUB_SUBNET_1" \
        --associate-public-ip-address \
        --user-data "$USER_DATA" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=sockshop-app-server},{Key=Project,Value=$PROJECT_TAG}]" \
        --query 'Instances[0].InstanceId' --output text)

    print_info "Waiting for instance to be running..."
    aws ec2 wait instance-running --region "$AWS_REGION" --instance-ids "$INSTANCE_ID"

    PUBLIC_IP=$(aws ec2 describe-instances --region "$AWS_REGION" \
        --instance-ids "$INSTANCE_ID" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

    print_success "EC2 instance: $INSTANCE_ID (IP: $PUBLIC_IP)"
    print_info "Sock Shop will be available in 5-10 minutes at http://${PUBLIC_IP}:8079"
}

###############################################################################
# RDS Database
###############################################################################

create_rds() {
    print_header "Step 4: Creating RDS Database"

    # Create DB subnet group
    aws rds create-db-subnet-group --region "$AWS_REGION" \
        --db-subnet-group-name sockshop-db-subnet-group \
        --db-subnet-group-description "Subnet group for Sock Shop databases" \
        --subnet-ids "$PRIV_SUBNET_1" "$PRIV_SUBNET_2" >/dev/null
    print_success "DB subnet group created"

    # Generate a random password
    DB_PASSWORD="SockShop$(date +%s | sha256sum | head -c 8)!"
    echo "$DB_PASSWORD" > /tmp/sockshop-db-password.txt
    chmod 600 /tmp/sockshop-db-password.txt

    # Create RDS instance
    aws rds create-db-instance --region "$AWS_REGION" \
        --db-instance-identifier sockshop-db \
        --db-instance-class db.t3.micro \
        --engine mysql \
        --engine-version 8.0 \
        --master-username admin \
        --master-user-password "$DB_PASSWORD" \
        --allocated-storage 20 \
        --storage-type gp3 \
        --db-subnet-group-name sockshop-db-subnet-group \
        --vpc-security-group-ids "$RDS_SG" \
        --db-name socksdb \
        --no-publicly-accessible \
        --backup-retention-period 0 \
        --no-multi-az \
        --tags Key=Project,Value=$PROJECT_TAG Key=Name,Value=sockshop-db >/dev/null

    print_success "RDS creation initiated (takes 5-10 minutes)"
    print_info "DB password saved to /tmp/sockshop-db-password.txt"
}

###############################################################################
# Application Load Balancer
###############################################################################

create_alb() {
    print_header "Step 5: Creating Application Load Balancer"

    # Create target group
    TG_ARN=$(aws elbv2 create-target-group --region "$AWS_REGION" \
        --name sockshop-tg \
        --protocol HTTP --port 8079 \
        --vpc-id "$VPC_ID" \
        --health-check-protocol HTTP \
        --health-check-path "/" \
        --health-check-interval-seconds 30 \
        --healthy-threshold-count 2 \
        --unhealthy-threshold-count 2 \
        --query 'TargetGroups[0].TargetGroupArn' --output text)
    print_success "Target group created"

    # Register EC2 instance
    aws elbv2 register-targets --region "$AWS_REGION" \
        --target-group-arn "$TG_ARN" \
        --targets Id="$INSTANCE_ID",Port=8079
    print_success "Instance registered in target group"

    # Create ALB
    ALB_ARN=$(aws elbv2 create-load-balancer --region "$AWS_REGION" \
        --name sockshop-alb \
        --subnets "$PUB_SUBNET_1" "$PUB_SUBNET_2" \
        --security-groups "$ALB_SG" \
        --scheme internet-facing \
        --type application \
        --tags Key=Project,Value=$PROJECT_TAG \
        --query 'LoadBalancers[0].LoadBalancerArn' --output text)
    print_success "ALB created"

    # Create listener
    aws elbv2 create-listener --region "$AWS_REGION" \
        --load-balancer-arn "$ALB_ARN" \
        --protocol HTTP --port 80 \
        --default-actions Type=forward,TargetGroupArn="$TG_ARN" >/dev/null
    print_success "Listener created (port 80 → target group port 8079)"

    # Get DNS name
    ALB_DNS=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" \
        --load-balancer-arns "$ALB_ARN" \
        --query 'LoadBalancers[0].DNSName' --output text)
    print_success "ALB DNS: $ALB_DNS"
}

###############################################################################
# Summary
###############################################################################

print_summary() {
    print_header "Setup Complete!"

    echo -e "${GREEN}All Day 1 resources have been created:${NC}"
    echo ""
    echo "  VPC:              $VPC_ID"
    echo "  Public Subnets:   $PUB_SUBNET_1, $PUB_SUBNET_2"
    echo "  Private Subnets:  $PRIV_SUBNET_1, $PRIV_SUBNET_2"
    echo "  EC2 Instance:     $INSTANCE_ID"
    echo "  EC2 Public IP:    $PUBLIC_IP"
    echo "  RDS Instance:     sockshop-db (creating...)"
    echo "  ALB DNS:          $ALB_DNS"
    echo ""
    echo -e "${YELLOW}Access Points:${NC}"
    echo "  Direct EC2:  http://${PUBLIC_IP}:8079 (available in ~5 min)"
    echo "  Via ALB:     http://${ALB_DNS} (available in ~5 min)"
    echo "  SSH:         ssh -i ~/.ssh/sockshop-key.pem ubuntu@${PUBLIC_IP}"
    echo ""
    echo -e "${YELLOW}Important:${NC}"
    echo "  - Sock Shop takes 5-10 minutes to fully start"
    echo "  - RDS takes 5-10 minutes to become available"
    echo "  - DB password saved to /tmp/sockshop-db-password.txt"
    echo "  - ALB costs ~\$0.50/day"
    echo "  - Run ./cleanup-day1.sh when done"
    echo ""
    echo -e "${GREEN}Verify deployment: ./verify-deployment.sh${NC}"
    echo -e "${GREEN}Check costs: ./check-costs.sh${NC}"
}

###############################################################################
# Main
###############################################################################

main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║  Day 1 - Automated Infrastructure Setup  ║"
    echo "║  AWS DevOps Learning Program             ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"

    preflight_check
    create_vpc
    create_security_groups
    create_ec2
    create_rds
    create_alb
    print_summary
}

main
