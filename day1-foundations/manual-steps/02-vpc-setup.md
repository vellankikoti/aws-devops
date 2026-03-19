# VPC & Networking Setup - Detailed Guide

## What We're Building

A production-style network on AWS with:
- 1 VPC (10.0.0.0/16) - 65,536 IP addresses
- 2 Public Subnets (for EC2, ALB) across 2 Availability Zones
- 2 Private Subnets (for RDS) across 2 Availability Zones
- 1 Internet Gateway (connects VPC to the internet)
- Route Tables (direct traffic correctly)

```
┌─────────────────────────────────────────────────────────────┐
│ VPC: 10.0.0.0/16 (sockshop-vpc)                            │
│                                                             │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │ AZ: us-east-1a       │  │ AZ: us-east-1b       │        │
│  │                      │  │                      │        │
│  │ ┌──────────────────┐ │  │ ┌──────────────────┐ │        │
│  │ │ Public Subnet    │ │  │ │ Public Subnet    │ │        │
│  │ │ 10.0.1.0/24      │ │  │ │ 10.0.2.0/24      │ │        │
│  │ │ (EC2, ALB)       │ │  │ │ (ALB)            │ │        │
│  │ └──────────────────┘ │  │ └──────────────────┘ │        │
│  │                      │  │                      │        │
│  │ ┌──────────────────┐ │  │ ┌──────────────────┐ │        │
│  │ │ Private Subnet   │ │  │ │ Private Subnet   │ │        │
│  │ │ 10.0.3.0/24      │ │  │ │ 10.0.4.0/24      │ │        │
│  │ │ (RDS)            │ │  │ │ (RDS standby)    │ │        │
│  │ └──────────────────┘ │  │ └──────────────────┘ │        │
│  └──────────────────────┘  └──────────────────────┘        │
│                                                             │
│  [Internet Gateway] ←→ Internet                             │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- [ ] AWS account setup complete ([01-aws-account-setup.md](./01-aws-account-setup.md))
- [ ] Logged in as IAM admin user (not root)
- [ ] AWS CLI configured and working (`aws sts get-caller-identity`)

## Concepts You Need to Know

### Public vs Private Subnets

| Feature | Public Subnet | Private Subnet |
|---------|--------------|----------------|
| Internet access | Yes (via Internet Gateway) | No direct access |
| Reachable from internet | Yes (if security group allows) | No |
| Use for | Web servers, load balancers | Databases, internal services |
| Route table | Has route to IGW (0.0.0.0/0 → igw-xxx) | No route to IGW |

### CIDR Notation Quick Reference

| CIDR | # of IPs | Example Range |
|------|----------|---------------|
| /16 | 65,536 | 10.0.0.0 - 10.0.255.255 |
| /24 | 256 | 10.0.1.0 - 10.0.1.255 |
| /28 | 16 | 10.0.1.0 - 10.0.1.15 |

**Note**: AWS reserves 5 IPs in each subnet (first 4 + last 1), so a /24 gives you 251 usable IPs.

## Step-by-Step: Create VPC via Console

### Step 1: Navigate to VPC Console

1. In AWS Console, search for **"VPC"** in the search bar
2. Click **"VPC"** to open the VPC Dashboard
3. Make sure you're in your desired region (top right) - recommend **us-east-1**

### Step 2: Create VPC with the Wizard

1. Click **"Create VPC"**
2. Choose **"VPC and more"** (this creates everything at once)
3. Configure:

| Setting | Value | Why |
|---------|-------|-----|
| Name tag auto-generation | `sockshop` | Consistent naming |
| IPv4 CIDR block | `10.0.0.0/16` | Large enough for growth |
| IPv6 CIDR block | No IPv6 | Simplicity for learning |
| Tenancy | Default | Dedicated is expensive |
| Number of Availability Zones | 2 | High availability |
| Number of public subnets | 2 | ALB requires 2 AZs |
| Number of private subnets | 2 | RDS requires 2 AZs |
| NAT gateways | None | Costs ~$32/month, skip for now |
| VPC endpoints | None | Not needed today |

4. Review the **Preview** panel on the right - it shows what will be created
5. Click **"Create VPC"**

### Step 3: Wait for Creation (1-2 minutes)

You'll see a progress page showing resources being created:
- ✅ VPC
- ✅ Subnets (4)
- ✅ Route tables (3 - 1 main + 2 custom)
- ✅ Internet Gateway
- ✅ Route table associations

### Step 4: Enable Auto-Assign Public IP on Public Subnets

**This is a common gotcha!** The wizard doesn't always enable this.

1. Go to **VPC Console → Subnets**
2. Select the first **public** subnet (e.g., `sockshop-subnet-public1-us-east-1a`)
3. Click **Actions → Edit subnet settings**
4. Check ✅ **"Enable auto-assign public IPv4 address"**
5. Click **Save**
6. Repeat for the second public subnet

**Why?** Without this, EC2 instances launched in public subnets won't get a public IP automatically.

## Verification via AWS CLI

Run these commands to verify everything was created correctly:

```bash
# Store VPC ID for later use
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=sockshop-vpc" \
  --query 'Vpcs[0].VpcId' \
  --output text)

echo "VPC ID: $VPC_ID"
```

### Verify Subnets

```bash
# List all subnets in your VPC
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

**Expected output:** 4 subnets across 2 AZs. Public subnets should show `True` for MapPublicIpOnLaunch.

### Verify Internet Gateway

```bash
# Check Internet Gateway is attached
aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query 'InternetGateways[*].[InternetGatewayId,Attachments[0].State]' \
  --output table
```

**Expected:** 1 Internet Gateway with state `available`.

### Verify Route Tables

```bash
# Check route tables
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[*].[RouteTableId,Routes[?DestinationCidrBlock==`0.0.0.0/0`].GatewayId|[0],Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

**Expected:** Public route tables should have a route to `igw-xxx`. Private route tables should NOT.

## Alternative: Create VPC via CLI

If you prefer the command line (or want to practice for Day 2):

```bash
# Create VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=sockshop-vpc},{Key=Project,Value=SockShop}]' \
  --query 'Vpc.VpcId' \
  --output text)

echo "Created VPC: $VPC_ID"

# Enable DNS hostnames (needed for RDS)
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-hostnames '{"Value":true}'

# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=sockshop-igw},{Key=Project,Value=SockShop}]' \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

echo "Created IGW: $IGW_ID"

# Attach IGW to VPC
aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID

# Create Public Subnets
PUB_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=sockshop-public-1a},{Key=Project,Value=SockShop}]' \
  --query 'Subnet.SubnetId' \
  --output text)

PUB_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=sockshop-public-1b},{Key=Project,Value=SockShop}]' \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Public Subnets: $PUB_SUBNET_1, $PUB_SUBNET_2"

# Enable auto-assign public IP on public subnets
aws ec2 modify-subnet-attribute \
  --subnet-id $PUB_SUBNET_1 \
  --map-public-ip-on-launch

aws ec2 modify-subnet-attribute \
  --subnet-id $PUB_SUBNET_2 \
  --map-public-ip-on-launch

# Create Private Subnets
PRIV_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.3.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=sockshop-private-1a},{Key=Project,Value=SockShop}]' \
  --query 'Subnet.SubnetId' \
  --output text)

PRIV_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.4.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=sockshop-private-1b},{Key=Project,Value=SockShop}]' \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Private Subnets: $PRIV_SUBNET_1, $PRIV_SUBNET_2"

# Create Route Table for Public Subnets
PUB_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=sockshop-public-rt},{Key=Project,Value=SockShop}]' \
  --query 'RouteTable.RouteTableId' \
  --output text)

# Add internet route to public route table
aws ec2 create-route \
  --route-table-id $PUB_RT \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

# Associate public subnets with public route table
aws ec2 associate-route-table \
  --route-table-id $PUB_RT \
  --subnet-id $PUB_SUBNET_1

aws ec2 associate-route-table \
  --route-table-id $PUB_RT \
  --subnet-id $PUB_SUBNET_2

echo "VPC setup complete!"
echo "VPC: $VPC_ID"
echo "Public Subnets: $PUB_SUBNET_1, $PUB_SUBNET_2"
echo "Private Subnets: $PRIV_SUBNET_1, $PRIV_SUBNET_2"
echo "Internet Gateway: $IGW_ID"
```

## Troubleshooting

### Issue: "The CIDR '10.0.0.0/16' conflicts with another subnet"

**Cause:** You already have a VPC with this CIDR range.
**Fix:** Delete the existing VPC first, or use a different CIDR (e.g., `172.16.0.0/16`).

### Issue: EC2 instances can't reach the internet

**Cause:** Usually a route table or Internet Gateway issue.
**Checklist:**
1. Internet Gateway attached to VPC? (`aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID"`)
2. Public subnet route table has 0.0.0.0/0 → igw-xxx route?
3. Instance is in a PUBLIC subnet (not private)?
4. Auto-assign public IP is enabled on the subnet?
5. Security group allows outbound traffic?

### Issue: "VPC limit exceeded"

**Cause:** Default limit is 5 VPCs per region.
**Fix:** Delete unused VPCs, or use a different region.

### Issue: Subnets showing wrong Availability Zone

**Cause:** You might be in a different region.
**Fix:** Check the region selector in the top-right of the console.

## Save Your Resource IDs

Write these down - you'll need them throughout Day 1:

```
VPC ID:              vpc-________________
Public Subnet 1:     subnet-________________ (AZ: ________)
Public Subnet 2:     subnet-________________ (AZ: ________)
Private Subnet 1:    subnet-________________ (AZ: ________)
Private Subnet 2:    subnet-________________ (AZ: ________)
Internet Gateway:    igw-________________
Public Route Table:  rtb-________________
```

## What You Learned

- How AWS networking works (VPC, subnets, routing, IGW)
- The difference between public and private subnets
- Why multi-AZ matters for high availability
- CIDR notation and IP address planning

## Next Step

Your network is ready. Now let's launch a compute instance in it.

**Next**: [03-ec2-setup.md](./03-ec2-setup.md) - Launch and configure your EC2 instance

---

**Time spent**: ~15-20 minutes
**Cost so far**: $0
**Resources created**: VPC, 4 subnets, Internet Gateway, route tables
