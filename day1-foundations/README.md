# Day 1: AWS Foundations & Manual Deployment

## My Take: Why We're Starting the Hard Way

Look, I know what you're thinking. "Koti, it's 2025. Why are we deploying things manually? Don't we have Terraform? Don't we have CI/CD?"

And you're absolutely right to ask that.

But here's something I learned the hard way at TransUnion when I was debugging a production issue at 3 AM: **you can't automate what you don't understand**. When your Terraform apply fails, when your Jenkins pipeline breaks, when your Kubernetes pods won't start - you need to know what's happening under the hood.

I've interviewed dozens of DevOps engineers who can recite Terraform syntax but freeze when I ask them "What actually happens when you create a VPC?" They've automated everything but understood nothing.

That's not you. Not after today.

Today, we're getting our hands dirty. We're clicking through the AWS Console. We're waiting for instances to launch. We're copying and pasting IP addresses. We're feeling the pain.

Because tomorrow, when we automate all of this with Terraform, you'll appreciate every single line of code. You'll understand why each resource exists. You'll know what can go wrong and how to fix it.

So buckle up. Today is intentionally painful. But it's the kind of pain that makes you stronger.

## What We're Building Today

By the end of today, you'll have deployed a complete microservices application on AWS:

- **Application**: Sock Shop (a realistic e-commerce microservices demo)
- **Infrastructure**: VPC, EC2 instances, RDS database, Application Load Balancer
- **Monitoring**: CloudWatch metrics, logs, and billing alerts
- **Cost**: $0 (Free Tier only, with one small exception we'll handle)

Here's what it looks like:

```
Internet
   |
   v
Application Load Balancer (distributes traffic)
   |
   v
EC2 Instance (Docker host running Sock Shop containers)
   |
   v
RDS MySQL Database (product catalog, user data)
   |
   v
CloudWatch (monitoring everything)
```

Don't worry about understanding this diagram right now. By tonight, you'll be able to explain every arrow, every box, every connection.

## Prerequisites

### What You Need to Know

Based on our Linux and Shell Scripting sections, you should be comfortable with:
- Basic Linux commands (cd, ls, mkdir, vim/nano)
- SSH and working with remote servers
- Basic understanding of IP addresses and ports
- What Docker containers are (don't need to be an expert)

### What You Need to Have

**AWS Account Setup (20 minutes):**
1. AWS Free Tier account (we'll set this up first)
2. A credit/debit card (AWS requires this, but we won't charge it if we stay in Free Tier)
3. A phone for verification
4. An email you check regularly

**On Your Local Machine:**
```bash
# Check if you have these tools
ssh -V          # Should show OpenSSH version
aws --version   # We'll install this if missing
docker --version # Optional for today, required later
```

**Time Commitment:**
- Morning Session (Setup): 2-3 hours
- Afternoon Session (Deployment): 3-4 hours
- Evening Session (Monitoring): 1-2 hours
- Total: 7-8 hours (with breaks!)

**My Advice**: Don't rush. This is day 1 of 7. Build the foundation right.

## Cost Breakdown (Transparency First)

I promised you free content. Here's the exact cost truth:

**Free Tier Services We'll Use:**
- EC2 t2.micro: 750 hours/month FREE
- RDS db.t3.micro: 750 hours/month FREE
- EBS Storage: 30GB FREE
- S3 Storage: 5GB FREE
- Data Transfer: 15GB out/month FREE

**The One Not-Free Thing:**
- Application Load Balancer: ~$0.50/day (~$3.50/week)

**Why ALB Isn't Free:**
AWS charges for ALB from the first hour. It's about $16-18/month if you run it 24/7.

**How to Keep It Free (Sort of):**
```bash
# Option 1: Use Classic Load Balancer (has free tier, but older)
# Option 2: Skip load balancer, use EC2 public IP (not production-grade)
# Option 3: Pay the $0.50/day (my recommendation - learn the real stuff)
```

**My Choice**: I'm using ALB. It's $3.50 for this week of learning. That's less than a coffee. And you learn how production load balancers actually work.

**Total Cost for Day 1**: $0.50 if we clean up tonight, $3.50 if we keep it running for the full 7 days.

## Part 1: AWS Account & Security Setup (Morning Session)

### Step 1: Creating Your AWS Account

This is straightforward, but let me point out the traps:

1. Go to https://aws.amazon.com/free
2. Click "Create a Free Account"
3. Use a proper email (not a disposable one - AWS sends important billing alerts here)
4. Create a strong password (store it in a password manager, you'll need this a lot)

**Trap #1**: AWS will ask for payment information. You need to add a card. But set up billing alerts (we'll do this) so you never get surprised.

**Trap #2**: Phone verification can be flaky. If it fails, try a different browser or use SMS instead of voice call.

### Step 2: Secure Your Root Account (CRITICAL)

Here's where most people mess up. The account you just created is your **root account**. It has unlimited power to do anything in your AWS account - including deleting everything or racking up a $10,000 bill.

Never use root for daily work. Never. I mean it.

**Enable MFA on Root Account Right Now:**

1. Log in as root
2. Click your account name (top right) → Security Credentials
3. Scroll to "Multi-factor authentication (MFA)"
4. Click "Activate MFA"
5. Choose "Virtual MFA device"
6. Use Google Authenticator or Authy on your phone
7. Scan the QR code
8. Enter two consecutive MFA codes
9. Done. Now your root account is protected.

**Why I'm Paranoid About This:**
At my previous company, someone's AWS account got compromised because they didn't have MFA. The attacker launched 50 p3.16xlarge instances (GPU instances for crypto mining). The bill was $12,000 in 8 hours. AWS waived it because it was obvious fraud, but the stress and recovery time? Not worth it.

Protect your account. Now.

### Step 3: Create Your IAM User (Your Daily Driver)

Now we create the account you'll actually use:

1. In AWS Console, search for "IAM" in the search bar
2. Click "Users" in the left sidebar
3. Click "Create user"
4. Username: `devops-admin` (or your name)
5. Check "Provide user access to AWS Management Console"
6. Choose "I want to create an IAM user"
7. Custom password: create a strong one
8. Uncheck "Users must create a new password at next sign-in" (we're adults)
9. Click Next

**Set Permissions:**
1. Choose "Attach policies directly"
2. Search for and select: `AdministratorAccess`
3. Click Next, then Create User

**Important**: Yes, we're giving this user admin access. In a real company, you'd have more restricted roles. But for learning, we need full access. Just don't share these credentials with anyone.

**Save Your Sign-In URL:**
After creating the user, you'll see a sign-in URL like:
```
https://123456789012.signin.aws.amazon.com/console
```

Bookmark this. This is YOUR login page. Not the main AWS page. This specific URL.

### Step 4: Set Up AWS CLI

We need the AWS CLI to run commands from our terminal:

**On Mac:**
```bash
brew install awscli
```

**On Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**On Windows (WSL):**
Same as Linux above.

**Verify Installation:**
```bash
aws --version
# Should show: aws-cli/2.x.x Python/3.x.x ...
```

**Configure AWS CLI:**

1. In AWS Console (logged in as your IAM user), click your username (top right)
2. Click "Security credentials"
3. Scroll to "Access keys"
4. Click "Create access key"
5. Choose "Command Line Interface (CLI)"
6. Check the confirmation box
7. Click Next, then Create Access Key
8. **IMPORTANT**: Download the CSV file or copy both Access Key ID and Secret Access Key. You can't see the secret again!

Now configure CLI:
```bash
aws configure
```

Enter:
- AWS Access Key ID: [paste your key]
- AWS Secret Access Key: [paste your secret]
- Default region: `us-east-1` (or your preferred region)
- Default output format: `json`

**Test It:**
```bash
aws sts get-caller-identity
```

You should see:
```json
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/devops-admin"
}
```

If you see this, you're in. You have CLI access to AWS.

### Step 5: Set Up Billing Alerts (Sleep Better at Night)

This is non-negotiable. Set this up NOW:

1. Click your account name (top right) → Billing Dashboard
2. In the left sidebar, click "Billing preferences"
3. Scroll to "Alert preferences"
4. Check all these boxes:
   - ✅ Receive AWS Free Tier alerts
   - ✅ Receive CloudWatch billing alerts
5. Enter your email
6. Save preferences

**Create a Budget:**
1. In Billing Dashboard, click "Budgets" in left sidebar
2. Click "Create budget"
3. Choose "Use a template"
4. Select "Zero spend budget"
5. Budget name: `free-tier-monitor`
6. Email recipients: [your email]
7. Create budget

**What This Does:**
You'll get an email if you spend even $0.01. Yes, it's aggressive. But you'll know immediately if something's wrong.

I once had a Lambda function stuck in a loop. The budget alert hit my phone at 2 AM. I stopped it before it cost more than $5. Worth the paranoia.

## Part 2: Understanding VPC (The Foundation)

Before we launch anything, we need to understand VPC. This is the #1 thing people skip and then get confused about later.

### What is a VPC? (The Real Explanation)

VPC = Virtual Private Cloud. It's your own private network inside AWS.

Think of it like this: AWS is a massive building with thousands of apartments. A VPC is YOUR apartment. Your private space. Your rules. Your furniture arrangement.

**Every AWS account comes with a default VPC**. We could use it. But we won't. Because:
1. Default VPCs are predictable (security issue)
2. You won't learn if you don't build it
3. In production, you'll always create custom VPCs

So we're creating our own.

### VPC Components (The Building Blocks)

**1. CIDR Block**: The IP address range for your VPC
```
Example: 10.0.0.0/16
This gives you 65,536 IP addresses (10.0.0.0 to 10.0.255.255)
```

**2. Subnets**: Divisions within your VPC
```
Public Subnet: 10.0.1.0/24 (256 addresses)
Private Subnet: 10.0.2.0/24 (256 addresses)
```

**3. Internet Gateway**: The door to the internet
**4. Route Tables**: The GPS telling traffic where to go
**5. Security Groups**: The firewall rules

Don't memorize this. We're about to build it and it'll make sense.

### Creating Our VPC (Step by Step)

**Step 1: Create the VPC**

1. In AWS Console, search for "VPC"
2. Click "Create VPC"
3. Choose "VPC and more" (this is a wizard that creates everything)
4. Settings:
   - Name tag: `sockshop-vpc`
   - IPv4 CIDR: `10.0.0.0/16`
   - IPv6: No IPv6 CIDR block
   - Tenancy: Default
   - Number of AZs: 2
   - Number of public subnets: 2
   - Number of private subnets: 2
   - NAT gateways: None (costs money, we don't need it today)
   - VPC endpoints: None
5. Click "Create VPC"

Wait 1-2 minutes. AWS is creating:
- 1 VPC
- 4 Subnets (2 public, 2 private)
- 1 Internet Gateway
- Route tables
- Network ACLs

**What Just Happened?**

You created a complete network. Here's what each piece does:

**Public Subnets** (`10.0.1.0/24` and `10.0.2.0/24`):
- Can reach the internet
- Internet can reach them (if we allow it)
- This is where we'll put our EC2 instances and Load Balancer

**Private Subnets** (`10.0.3.0/24` and `10.0.4.0/24`):
- Can NOT reach the internet directly
- Internet can NOT reach them
- This is where we'll put our RDS database (extra security)

**Why Two of Each?**
AWS Availability Zones (AZs) are physically separate data centers. If one catches fire (happened before), the other keeps running. We're building for high availability from day 1.

**Step 2: Verify Your VPC**

```bash
# List your VPCs (using filter for better results)
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=sockshop-vpc" \
  --query 'Vpcs[*].[VpcId,CidrBlock,State,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

You should see your VPC with CIDR block `10.0.0.0/16`.

**Alternative: Get VPC ID only**
```bash
# Get just the VPC ID
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=sockshop-vpc" \
  --query 'Vpcs[0].VpcId' \
  --output text
```

**Step 3: Check Your Subnets**

First, get your VPC ID, then list subnets in that VPC:

```bash
# Method 1: Get VPC ID first, then list subnets
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=sockshop-vpc" \
  --query 'Vpcs[0].VpcId' \
  --output text)

echo "VPC ID: $VPC_ID"

# List all subnets in your VPC
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

**Method 2: One-liner (if you know the VPC ID)**
```bash
# Replace vpc-xxxxx with your actual VPC ID
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-xxxxx" \
  --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

You should see 4 subnets across 2 availability zones (2 public, 2 private).

### Understanding Security Groups (Your Firewall)

Security Groups are stateful firewalls. They control what traffic can reach your resources.

**Key Concepts:**
- **Inbound rules**: What can come IN to your resource
- **Outbound rules**: What can go OUT from your resource
- **Stateful**: If you allow inbound traffic, the response is automatically allowed out (you don't need separate outbound rules for responses)

We'll create these as we need them. But remember: **By default, everything is denied**. You have to explicitly allow what you want.

## Part 3: Launching Your First EC2 Instance (The Fun Begins)

This is it. We're launching a server on AWS.

### Step 1: Create a Key Pair (Your SSH Key)

You need this to SSH into your EC2 instance:

1. In EC2 Console, click "Key Pairs" in left sidebar
2. Click "Create key pair"
3. Settings:
   - Name: `sockshop-key`
   - Key pair type: RSA
   - Private key file format: `.pem` (for Mac/Linux) or `.ppk` (for Windows/PuTTY)
4. Click "Create key pair"

Your browser downloads `sockshop-key.pem`. Save it somewhere safe.

**Set Permissions (Mac/Linux):**
```bash
chmod 400 ~/Downloads/sockshop-key.pem
```

This makes the key read-only. SSH requires this.

### Step 2: Create Security Group for EC2

1. In EC2 Console, click "Security Groups"
2. Click "Create security group"
3. Settings:
   - Name: `sockshop-ec2-sg`
   - Description: `Security group for Sock Shop EC2 instance`
   - VPC: Choose `sockshop-vpc`
4. Add Inbound Rules:

```
Type: SSH
Port: 22
Source: My IP (this restricts SSH to only YOUR IP address)
Description: SSH access

Type: HTTP
Port: 80
Source: 0.0.0.0/0 (anywhere - we need this for the load balancer)
Description: HTTP from ALB

Type: Custom TCP
Port: 8080
Source: 0.0.0.0/0
Description: Sock Shop frontend
```

5. Leave Outbound Rules as default (allows all outbound)
6. Create security group

**Why These Rules?**
- SSH (22): So we can log in and configure the instance
- HTTP (80): So the load balancer can send traffic to our app
- 8080: The Sock Shop frontend runs on this port

### Step 3: Launch EC2 Instance

Now for the main event:

1. In EC2 Console, click "Launch Instance"
2. Name: `sockshop-app-server`
3. **Application and OS Images (Amazon Machine Image)**:
   - Choose "Amazon Linux 2023 AMI"
   - Architecture: 64-bit (x86)
4. **Instance Type**:
   - Choose `t2.micro` (Free Tier eligible - you'll see a green label)
5. **Key pair**:
   - Select `sockshop-key` (the one we just created)
6. **Network settings** - Click Edit:
   - VPC: `sockshop-vpc`
   - Subnet: Choose one of your PUBLIC subnets (e.g., `sockshop-vpc-subnet-public1-us-east-1a`)
   - Auto-assign public IP: Enable
   - Firewall (security groups): Select existing security group
   - Select: `sockshop-ec2-sg`
7. **Configure storage**:
   - 8 GB gp3 (default is fine, within Free Tier)
8. **Advanced details** - Expand this:
   - Scroll to "User data" (at the bottom)
   - Paste this script:

```bash
#!/bin/bash
# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install git
yum install -y git

# Log completion
echo "User data script completed" > /tmp/user-data-complete.txt
```

9. **Summary**: Review everything
10. Click "Launch instance"

**What Just Happened?**

AWS is now:
1. Allocating a physical server in their data center
2. Installing Amazon Linux on it
3. Configuring networking
4. Running your user data script (installing Docker, Docker Compose, Git)
5. Starting the instance

This takes 2-3 minutes.

**Step 4: Wait and Connect**

1. Go to "Instances" in EC2 Console
2. Select your instance (`sockshop-app-server`)
3. Wait for:
   - Instance State: Running ✅
   - Status Checks: 2/2 checks passed ✅

4. Note the **Public IPv4 address** (something like `54.123.45.67`)

**Step 5: SSH Into Your Instance**

```bash
# Replace with your actual IP and key path
ssh -i ~/Downloads/sockshop-key.pem ec2-user@54.123.45.67
```

If you see a warning about authenticity, type `yes`.

You should see:
```
   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
  ~~     \###|
  ~~       \#/ ___
   ~~       V~' '->
    ~~~         /
      ~~._.   _/
         _/ _/
       _/m/'

[ec2-user@ip-10-0-1-123 ~]$
```

**You're in**. You're SSH'd into a server running on AWS. This is your computer in the cloud.

**Verify User Data Script Ran:**
```bash
# Check if script completed
cat /tmp/user-data-complete.txt

# Check Docker is installed
docker --version

# Check Docker Compose is installed
docker-compose --version
```

If all three work, we're good. If not, the user data script might still be running. Wait 1-2 minutes and check again.

## Part 4: Deploying Sock Shop (Making It Real)

Now we deploy our application. Sock Shop is a microservices demo that looks like a real e-commerce site.

### Step 1: Get the Sock Shop Code

Still SSH'd into your EC2 instance:

```bash
# Clone the repository
cd /home/ec2-user
git clone https://github.com/microservices-demo/microservices-demo.git
cd microservices-demo/deploy/docker-compose
```

**What We Just Got:**
This repository contains Docker Compose files that define all the Sock Shop microservices: frontend, catalog, cart, orders, payment, shipping, user management, and databases.

### Step 2: Review the Docker Compose File

```bash
# Look at what we're deploying
cat docker-compose.yml
```

You'll see multiple services. The main ones:
- `front-end`: The web UI (what users see)
- `catalogue`: Product catalog service
- `catalogue-db`: MySQL database for products
- `carts`: Shopping cart service
- `carts-db`: MongoDB for carts
- `orders`: Order processing service
- `orders-db`: MongoDB for orders
- `shipping`: Shipping calculation service
- `queue-master`: Message queue service
- `rabbitmq`: Message broker
- `payment`: Payment processing service
- `user`: User authentication service
- `user-db`: MongoDB for users

This is a realistic microservices application. In production, you'd have similar complexity.

### Step 3: Deploy Sock Shop

```bash
# Make sure we're in the right directory
pwd
# Should show: /home/ec2-user/microservices-demo/deploy/docker-compose

# Start all services
docker-compose up -d
```

The `-d` flag means "detached" - it runs in the background.

**What's Happening:**
Docker is now:
1. Downloading all the container images (this takes 5-10 minutes on first run)
2. Creating networks for the containers to communicate
3. Starting all the services in the right order
4. Setting up databases

**Monitor the Progress:**
```bash
# Watch the logs
docker-compose logs -f

# Press Ctrl+C to stop watching (containers keep running)

# Check running containers
docker ps
```

You should see about 13-14 containers running.

**Step 4: Verify Sock Shop is Running**

```bash
# Check which ports are listening
netstat -tlnp | grep docker-proxy
```

You should see port `8079` (that's the Sock Shop frontend).

**Step 5: Test Locally on the Instance**

```bash
# Test from inside the instance
curl http://localhost:8079

# You should see HTML output starting with <!DOCTYPE html>
```

If you see HTML, Sock Shop is running!

### Step 6: Test from Your Browser

Remember that Public IP we noted earlier? Let's try to access it:

```
http://54.123.45.67:8079
```

**If it doesn't work**, we need to update the security group:

1. Go to EC2 Console → Security Groups
2. Select `sockshop-ec2-sg`
3. Edit Inbound Rules
4. Add Rule:
   - Type: Custom TCP
   - Port: 8079
   - Source: My IP (or 0.0.0.0/0 for testing)
   - Description: Sock Shop frontend
5. Save rules

Now try again: `http://your-ec2-public-ip:8079`

**You should see the Sock Shop homepage!**

A fully functional e-commerce site. With a product catalog. Shopping cart. Checkout. All running on microservices. On AWS. Deployed by you.

Click around. Add items to cart. It all works.

## Part 5: Setting Up RDS Database (Production-Grade Data)

Right now, Sock Shop is using containerized databases (MongoDB and MySQL running in Docker). That's fine for testing, but not for production.

In production, you use managed databases like RDS. Let's set that up.

### Why RDS Instead of Database Containers?

**RDS gives you:**
- Automated backups
- Automated patching
- High availability (Multi-AZ)
- Better performance
- Easier monitoring
- Disaster recovery

**You give up:**
- Some control (can't SSH into the database server)
- Flexibility (can't install custom extensions easily)

For production, it's worth it. Let me tell you why.

At TransUnion, we manage hundreds of databases. We used to run some in containers. The problems:
- A node dies, data is gone (unless you have persistent volumes set up perfectly)
- Backups are your responsibility
- Upgrades are manual and risky
- Monitoring requires custom setup

With RDS:
- AWS handles all that
- We focus on our application
- Sleep better at night

### Step 1: Create DB Subnet Group

RDS needs to know which subnets it can use. We'll use our private subnets (more secure).

1. In AWS Console, search for "RDS"
2. In left sidebar, click "Subnet groups"
3. Click "Create DB subnet group"
4. Settings:
   - Name: `sockshop-db-subnet-group`
   - Description: `Subnet group for Sock Shop databases`
   - VPC: Choose `sockshop-vpc`
5. Add subnets:
   - Choose both availability zones
   - Select your PRIVATE subnets (10.0.3.0/24 and 10.0.4.0/24)
6. Click "Create"

### Step 2: Create Security Group for RDS

1. Go to EC2 Console → Security Groups
2. Click "Create security group"
3. Settings:
   - Name: `sockshop-rds-sg`
   - Description: `Security group for Sock Shop RDS database`
   - VPC: `sockshop-vpc`
4. Add Inbound Rule:
```
Type: MySQL/Aurora
Port: 3306
Source: Custom - Choose the security group ID of sockshop-ec2-sg
Description: MySQL from EC2 instances
```

5. Create security group

**What This Does:**
Only our EC2 instances can connect to the database. The internet cannot. This is defense in depth.

### Step 3: Create RDS MySQL Instance

1. In RDS Console, click "Create database"
2. Choose a database creation method: **Standard create**
3. Engine options:
   - Engine type: MySQL
   - Engine version: MySQL 8.0.35 (or latest 8.0.x)
4. Templates: **Free tier** (this limits options to free tier only)
5. Settings:
   - DB instance identifier: `sockshop-db`
   - Master username: `admin`
   - Master password: Create a strong password (write it down securely)
   - Confirm password
6. DB instance class: `db.t3.micro` (should be auto-selected)
7. Storage:
   - Storage type: General Purpose SSD (gp3)
   - Allocated storage: 20 GB (minimum)
   - Uncheck "Enable storage autoscaling" (can cost money)
8. Connectivity:
   - VPC: `sockshop-vpc`
   - DB subnet group: `sockshop-db-subnet-group`
   - Public access: **No** (important!)
   - VPC security group: Choose existing
   - Select: `sockshop-rds-sg`
   - Availability Zone: No preference
9. Database authentication: Password authentication
10. Additional configuration - Expand:
    - Initial database name: `socksdb`
    - Uncheck "Enable automated backups" (free tier only gives 7 days, but consumes storage)
    - Uncheck "Enable encryption" (not available in free tier)
11. Click "Create database"

**Wait Time: 5-10 minutes**

AWS is provisioning a managed MySQL database server. This includes:
- Setting up the compute instance
- Configuring storage
- Installing MySQL
- Setting up networking
- Applying security configurations

Grab a coffee. You've earned it.

### Step 4: Get the RDS Endpoint

Once the database status is "Available":

1. Click on `sockshop-db` in the RDS console
2. In the "Connectivity & security" tab, note the **Endpoint**
   - It looks like: `sockshop-db.abc123def456.us-east-1.rds.amazonaws.com`
3. Copy this. We'll need it.

### Step 5: Connect to RDS from EC2

SSH back into your EC2 instance:

```bash
# Install MySQL client
sudo yum install -y mysql

# Connect to RDS (replace with your endpoint and password)
mysql -h sockshop-db.abc123def456.us-east-1.rds.amazonaws.com -u admin -p
```

Enter your password when prompted.

If you see:
```
mysql>
```

**You're connected to your RDS database!**

**Create the schema:**
```sql
SHOW DATABASES;
USE socksdb;

-- Create a test table
CREATE TABLE test (id INT, message VARCHAR(100));
INSERT INTO test VALUES (1, 'RDS is working!');
SELECT * FROM test;

-- Exit
EXIT;
```

If this works, your RDS database is fully functional.

**Note for Sock Shop Integration:**
Sock Shop's catalog service expects specific database schema. We won't fully migrate the database today (that's complex and we're focused on infrastructure), but we've proven we can:
1. Create RDS instances
2. Connect from EC2
3. Run queries

In Day 2 with Terraform, we'll automate creating the full schema.

## Part 6: Application Load Balancer (Production Traffic Management)

Right now, users access Sock Shop via the EC2 instance's public IP on port 8079. That's not production-ready. Here's why:

**Problems with Direct EC2 Access:**
1. If the EC2 instance dies, your site is down
2. You can't scale horizontally (add more instances)
3. No SSL/TLS termination
4. No health checks
5. The IP address changes if you restart the instance

**Solution: Application Load Balancer**

ALB sits in front of your EC2 instances and:
- Distributes traffic across multiple instances
- Performs health checks (reroutes if an instance is unhealthy)
- Provides a stable DNS name
- Can terminate SSL/TLS (HTTPS)
- Handles traffic spikes

### Step 1: Create Target Group

A target group is a collection of EC2 instances that receive traffic from the load balancer.

1. In EC2 Console, scroll down to "Target Groups"
2. Click "Create target group"
3. Basic configuration:
   - Target type: Instances
   - Target group name: `sockshop-tg`
   - Protocol: HTTP
   - Port: 8079
   - VPC: `sockshop-vpc`
4. Health checks:
   - Protocol: HTTP
   - Path: `/`
   - Healthy threshold: 2
   - Unhealthy threshold: 2
   - Timeout: 5
   - Interval: 30
5. Click Next
6. Register targets:
   - Select your `sockshop-app-server` instance
   - Port: 8079
   - Click "Include as pending below"
7. Click "Create target group"

**What This Does:**
The target group will continuously check if your EC2 instance is healthy by making HTTP requests to `http://instance-ip:8079/` every 30 seconds. If it gets 2 consecutive successful responses, the instance is marked healthy. If it gets 2 consecutive failures, it's marked unhealthy and removed from rotation.

### Step 2: Create Security Group for ALB

1. EC2 Console → Security Groups → Create security group
2. Settings:
   - Name: `sockshop-alb-sg`
   - Description: `Security group for Sock Shop ALB`
   - VPC: `sockshop-vpc`
3. Inbound rules:
```
Type: HTTP
Port: 80
Source: 0.0.0.0/0
Description: Allow HTTP from internet
```

4. Outbound rules: Keep default (all traffic allowed)
5. Create

### Step 3: Create Application Load Balancer

1. In EC2 Console, click "Load Balancers"
2. Click "Create load balancer"
3. Choose "Application Load Balancer"
4. Basic configuration:
   - Name: `sockshop-alb`
   - Scheme: Internet-facing
   - IP address type: IPv4
5. Network mapping:
   - VPC: `sockshop-vpc`
   - Mappings: Select BOTH availability zones
   - For each AZ, select the PUBLIC subnet
6. Security groups:
   - Remove default
   - Select: `sockshop-alb-sg`
7. Listeners and routing:
   - Protocol: HTTP
   - Port: 80
   - Default action: Forward to `sockshop-tg`
8. Click "Create load balancer"

**Wait Time: 2-3 minutes** for the ALB to become active.

### Step 4: Update EC2 Security Group

Now that we have an ALB, we should restrict EC2 to only accept traffic from the ALB:

1. EC2 Console → Security Groups
2. Select `sockshop-ec2-sg`
3. Edit Inbound rules
4. Find the rule for port 8079
5. Change Source from `0.0.0.0/0` to the security group ID of `sockshop-alb-sg`
6. Save

**What This Does:**
Now ONLY the load balancer can reach port 8079 on your EC2 instance. Direct internet access is blocked. This is more secure and forces all traffic through the ALB.

### Step 5: Test the ALB

1. Go to EC2 Console → Load Balancers
2. Click on `sockshop-alb`
3. Copy the **DNS name** (looks like: `sockshop-alb-1234567890.us-east-1.elb.amazonaws.com`)
4. Open in browser: `http://sockshop-alb-1234567890.us-east-1.elb.amazonaws.com`

**If you see Sock Shop, congratulations!** You have a production-grade load balancer in front of your application.

**If you don't see it:**
1. Check target group health:
   - EC2 Console → Target Groups → `sockshop-tg`
   - Click "Targets" tab
   - Status should be "healthy"
   - If "unhealthy", check health check settings and security groups
2. Wait 1-2 minutes - ALBs take time to provision and start routing traffic

## Part 7: CloudWatch Monitoring (Know What's Happening)

You can't manage what you can't measure. Let's set up monitoring.

### Step 1: EC2 Metrics (Out of the Box)

AWS automatically collects basic metrics for EC2:

1. Go to EC2 Console → Instances
2. Select your instance
3. Click "Monitoring" tab

You'll see graphs for:
- CPU Utilization
- Network In/Out
- Disk Read/Write
- Status Checks

These are free and update every 5 minutes.

**Enable Detailed Monitoring (Optional, Costs $):**
- Right-click instance → Manage detailed monitoring → Enable
- This gives 1-minute granularity instead of 5-minute
- Costs ~$2.10/month per instance
- We won't enable this (staying free tier), but know it exists

### Step 2: Create CloudWatch Dashboard

Let's create a custom dashboard to see all our metrics in one place:

1. Search for "CloudWatch" in AWS Console
2. Click "Dashboards" in left sidebar
3. Click "Create dashboard"
4. Dashboard name: `sockshop-dashboard`
5. Click "Create dashboard"

**Add EC2 Widget:**
1. Click "Add widget"
2. Choose "Line" widget
3. Under "Metrics", navigate:
   - EC2 → Per-Instance Metrics
   - Find your instance ID
   - Select: CPUUtilization
4. Click "Create widget"

**Add RDS Widget:**
1. Click "Add widget"
2. Choose "Line" widget
3. Under "Metrics", navigate:
   - RDS → Per-Database Metrics
   - Find your database identifier
   - Select: DatabaseConnections, CPUUtilization
4. Click "Create widget"

**Add ALB Widget:**
1. Click "Add widget"
2. Choose "Number" widget
3. Under "Metrics", navigate:
   - ApplicationELB → Per-AppELB Metrics
   - Find your ALB
   - Select: TargetResponseTime, RequestCount
4. Click "Create widget"

5. Click "Save dashboard"

**What You Have Now:**
A single dashboard showing:
- EC2 CPU usage
- RDS connections and CPU
- ALB request count and response time

In production, I have dashboards like this on a big screen in the office. When things go wrong, you see it immediately.

### Step 3: Set Up Alarms

Dashboards are nice, but alarms wake you up when things break.

**Create CPU Alarm:**
1. CloudWatch → Alarms → Create alarm
2. Select metric:
   - EC2 → Per-Instance Metrics
   - Your instance → CPUUtilization
3. Conditions:
   - Threshold type: Static
   - Whenever CPUUtilization is: Greater than
   - Than: 80
4. Configure actions:
   - Alarm state trigger: In alarm
   - Send notification to: Create new topic
   - Topic name: `sockshop-alerts`
   - Email: [your email]
5. Alarm name: `sockshop-ec2-high-cpu`
6. Click "Create alarm"

**Check your email** - AWS sends a subscription confirmation. Click the link to confirm.

Now if your CPU goes above 80%, you'll get an email.

**Create Additional Alarms (Optional):**
- RDS DatabaseConnections > 50
- ALB TargetResponseTime > 1 second
- ALB UnHealthyHostCount > 0

These catch problems before users complain.

### Step 4: View Logs

**EC2 Instance Logs:**
```bash
# SSH into your instance
ssh -i ~/Downloads/sockshop-key.pem ec2-user@your-ec2-ip

# View Docker logs
docker-compose -f /home/ec2-user/microservices-demo/deploy/docker-compose/docker-compose.yml logs

# View specific service logs
docker logs <container-id>
```

**RDS Logs:**
1. RDS Console → Your database → Logs & events tab
2. You can see error logs, slow query logs, general logs

For production, you'd send these to CloudWatch Logs. We'll set that up in Day 6 when we do full observability.

## Part 8: Cost Monitoring (The Most Important Section)

This is where people mess up. They launch resources and forget them. The bill comes. Panic ensues.

Let's make sure that doesn't happen to you.

### Step 1: Check Your Current Costs

1. Click your account name → Billing Dashboard
2. Look at "Month-to-Date Spend"

Right now, you should see:
- **$0.00** or very close to it

The only thing costing money is the ALB (~$0.50/day).

### Step 2: Cost Allocation Tags

Let's tag everything so we can track costs by project:

**Tag Your Resources:**
1. EC2 Console → Instances → Select your instance → Tags
2. Add tag:
   - Key: `Project`
   - Value: `SockShop`
3. Repeat for:
   - RDS database
   - Load balancer
   - Security groups
   - VPC

**Why?**
In a few days, you can filter costs by tag and see exactly what Sock Shop is costing you vs other projects.

### Step 3: Set Up AWS Budgets (If You Haven't)

We did this earlier, but let's verify:

1. Billing Dashboard → Budgets
2. You should see `free-tier-monitor`
3. If not, create it now:
   - Template: Zero spend budget
   - Email: [your email]

### Step 4: Understand Free Tier Usage

1. Billing Dashboard → Free Tier
2. You'll see a table showing:
   - Service name
   - Usage limit
   - Current usage
   - Percentage used

**Today's usage should show:**
- EC2 t2.micro: ~8-10 hours used out of 750
- RDS db.t3.micro: ~8-10 hours used out of 750
- EBS: ~8 GB used out of 30 GB

Everything is well within limits.

**Red Flags:**
- If any service is over 80% in the first week, something's wrong
- If you see services you didn't create, investigate immediately

### Step 5: Daily Cost Check Routine

**My Recommendation:**
For the next 7 days, check your billing dashboard once per day. Takes 30 seconds.

**What to look for:**
- Total spend should increase by ~$0.50/day (just the ALB)
- Free tier usage should increase proportionally
- No unexpected services

If you see anything weird, stop and investigate.

## Part 9: Testing the Complete System

Let's verify everything works end-to-end.

### Test 1: Access Sock Shop via ALB

```
http://your-alb-dns-name.elb.amazonaws.com
```

You should see the Sock Shop homepage.

### Test 2: Create an Account

1. Click "Login" on Sock Shop
2. Click "Register"
3. Create an account:
   - Username: test
   - Password: test
   - Email: test@test.com
4. Login

If this works, the user service and user database (MongoDB) are functional.

### Test 3: Browse Products

1. Click on a product
2. View details
3. Add to cart

If this works, the catalog service and catalog database are functional.

### Test 4: Place an Order

1. Go to cart
2. Click "Proceed to Checkout"
3. Add a fake address
4. Add a fake credit card (doesn't validate)
5. Complete order

If this works, the orders, payment, and shipping services are all functional.

**Congratulations.** You just successfully tested a multi-service application running on AWS.

### Test 5: Verify High Availability

Let's break something and see if we can recover:

```bash
# SSH into your instance
ssh -i ~/Downloads/sockshop-key.pem ec2-user@your-ec2-ip

# Stop one of the services
docker stop $(docker ps | grep front-end | awk '{print $1}')

# Check the site
# It should be down or broken
```

Now restart it:
```bash
# Restart the service
cd /home/ec2-user/microservices-demo/deploy/docker-compose
docker-compose up -d

# The service restarts
# Site is back up
```

**In Production:**
With multiple instances behind the ALB, if one instance fails, the ALB routes traffic to healthy instances. Users don't notice. We'll build that in Day 2.

## Part 10: Documentation & Architecture Diagram

Let's document what we built.

### Architecture Diagram

```
Internet
   |
   | HTTP (Port 80)
   v
[Application Load Balancer]
   | (sockshop-alb)
   | Port 8079
   v
[EC2 Instance - t2.micro]
   | (sockshop-app-server)
   | Amazon Linux 2023
   | Docker + Docker Compose
   |
   +-- [Sock Shop Containers]
        - front-end (8079)
        - catalogue + MySQL
        - carts + MongoDB
        - orders + MongoDB
        - payment
        - shipping
        - user + MongoDB
        - queue-master + RabbitMQ

   | Port 3306
   v
[RDS MySQL Instance]
   (sockshop-db)
   db.t3.micro
   20 GB storage

[CloudWatch]
   - Monitoring all resources
   - Alarms configured
   - Dashboard created
```

### What We Built

**Networking:**
- VPC: 10.0.0.0/16
- 2 Public Subnets (ALB, EC2)
- 2 Private Subnets (RDS)
- Internet Gateway
- Route Tables
- Security Groups

**Compute:**
- 1 EC2 t2.micro instance
- Docker + Docker Compose installed
- 13-14 microservice containers running

**Database:**
- 1 RDS MySQL db.t3.micro instance
- In private subnet
- Accessible only from EC2

**Load Balancing:**
- Application Load Balancer
- Target Group with health checks
- Stable DNS endpoint

**Monitoring:**
- CloudWatch dashboard
- CPU and connection alarms
- Cost monitoring
- Free tier tracking

**Cost:**
- Total: ~$0.50/day
- EC2: $0 (Free Tier)
- RDS: $0 (Free Tier)
- ALB: ~$0.50/day
- Storage: $0 (Free Tier)

## Common Mistakes I Made (So You Don't Have To)

### Mistake #1: Forgetting to Enable Public IP on EC2

**What happens:** You launch an EC2 instance in a public subnet but forget to enable "Auto-assign public IP". Now you can't SSH into it or access it from the internet.

**How to fix:**
- You can't add a public IP to a running instance
- You have to allocate an Elastic IP and associate it (which counts against your free tier)
- Or terminate and relaunch with public IP enabled

**Prevention:** Always check "Auto-assign public IP: Enable" when launching in public subnets.

### Mistake #2: Wrong Security Group Rules

**What happens:** You create a security group but forget to add the right rules. Your application is running, but you can't access it.

**How to fix:**
1. Go to Security Groups
2. Edit inbound rules
3. Add the missing rule
4. **IMPORTANT**: Changes apply immediately (no restart needed)

**Prevention:** Test connectivity after each resource creation. Don't wait until the end.

### Mistake #3: Using the Same Security Group for Everything

**What happens:** You create one security group and use it for EC2, RDS, and ALB. Now everything can talk to everything. Security nightmare.

**How to fix:**
- Create separate security groups for each layer
- Follow principle of least privilege
- EC2 should only accept traffic from ALB
- RDS should only accept traffic from EC2

**Prevention:** Create purpose-specific security groups from the start.

### Mistake #4: Not Setting Up Billing Alarms

**What happens:** You launch resources for testing. Forget about them. They run for a month. Bill is $200.

**How to fix:**
- Set up billing alarms BEFORE launching anything
- Use zero-spend budgets
- Check billing dashboard daily during learning

**Prevention:** First thing you do in a new AWS account: set up billing alerts.

### Mistake #5: Launching in the Wrong Availability Zone

**What happens:** You launch your EC2 in us-east-1a and your RDS in us-east-1b. There's network latency between AZs (small, but measurable).

**How to fix:**
- For single-instance setups, launch everything in the same AZ
- For HA setups, intentionally use multiple AZs

**Prevention:** Pay attention to AZ selection during resource creation.

### Mistake #6: Not Cleaning Up

**What happens:** You finish for the day. Leave everything running. Come back tomorrow. Another $0.50 gone. Not much, but it adds up.

**How to fix:**
- If you're done for the day and don't need it running, stop EC2 instances
- Or terminate everything and recreate tomorrow (we're learning, not running production)

**Prevention:** Use the cleanup script (we'll create this next).

## Production Tips from the Trenches

### Tip #1: Always Use Infrastructure as Code

We did everything manually today. Tomorrow, we'll do the same thing with Terraform in 5 minutes. That's the power of IaC.

**In production:**
- Never click through the console for important resources
- Always use Terraform, CloudFormation, or CDK
- Version control your infrastructure
- Peer review infrastructure changes

**Why?**
- Repeatability: Spin up identical environments
- Disaster recovery: Rebuild from code
- Audit trail: Git history shows who changed what
- Testing: Create test environments easily

### Tip #2: Tag Everything from Day One

We tagged resources at the end. In production, tag them immediately.

**Useful tags:**
```
Project: SockShop
Environment: dev|staging|prod
Owner: your-name
CostCenter: your-team
ManagedBy: terraform
CreatedDate: 2025-12-28
```

**Why?**
- Cost allocation
- Resource organization
- Automated cleanup (delete all resources tagged "Environment: test")
- Compliance and governance

### Tip #3: Use Parameter Store or Secrets Manager

We hardcoded database passwords. In production, never do this.

**Use AWS Systems Manager Parameter Store:**
```bash
# Store a secret
aws ssm put-parameter \
  --name "/sockshop/db/password" \
  --value "your-password" \
  --type "SecureString"

# Retrieve in your application
aws ssm get-parameter \
  --name "/sockshop/db/password" \
  --with-decryption
```

**Or AWS Secrets Manager** (more features, costs $0.40/month per secret).

### Tip #4: Enable VPC Flow Logs

We didn't enable these (they cost a tiny bit for storage), but in production, always enable VPC Flow Logs.

**What they do:**
- Log all network traffic in your VPC
- Helps with security analysis
- Troubleshoot connectivity issues
- Detect unusual patterns

**How to enable:**
1. VPC Console → Your VPC → Flow Logs
2. Create flow log
3. Send to CloudWatch Logs or S3

### Tip #5: Use Multi-AZ for Everything Critical

We used 2 AZs for our VPC, but only 1 EC2 instance. In production, use multiple AZs for everything:

- **RDS**: Enable Multi-AZ (automatic failover)
- **EC2**: Run instances in multiple AZs behind ALB
- **EBS snapshots**: Stored across multiple AZs automatically

**Why?**
AWS AZs fail. It's rare, but it happens. In 2020, us-east-1 had a major outage. Single-AZ deployments were down. Multi-AZ deployments kept running.

### Tip #6: Right-Size from the Start

We used t2.micro because it's free. In production, use CloudWatch metrics to determine the right instance size.

**Don't:**
- Use t2.micro for a production database (too small)
- Use m5.4xlarge for a simple web app (too expensive)

**Do:**
- Start with a reasonable size (maybe t3.medium)
- Monitor CPU, memory, network for 1-2 weeks
- Adjust based on actual usage
- Use Auto Scaling to handle spikes

### Tip #7: Implement Least Privilege Access

We gave our IAM user AdministratorAccess. In production, create specific roles:

- **Developers**: Can deploy applications, can't delete VPCs
- **DevOps**: Can manage infrastructure, can't access customer data
- **Read-only**: Can view everything, can't change anything

Use IAM policies to enforce this.

## Cleanup (Important!)

If you want to keep this running for Day 2 tomorrow, skip this section.

If you want to delete everything and avoid any costs:

### Option 1: Stop Resources (Keep Configuration)

```bash
# Stop EC2 instance (doesn't delete, just stops it)
aws ec2 stop-instances --instance-ids <your-instance-id>

# Stop RDS instance (creates a snapshot first)
aws rds stop-db-instance --db-instance-identifier sockshop-db
```

**Cost while stopped:**
- EC2: $0 (you only pay when running)
- RDS: ~$0.10/day (you still pay for storage)
- ALB: $0.50/day (you pay even when there's no traffic)

### Option 2: Delete Everything (Clean Slate)

**Important:** Do this in order or dependencies will prevent deletion.

1. **Delete ALB:**
   - EC2 Console → Load Balancers → Select → Actions → Delete

2. **Delete Target Group:**
   - EC2 Console → Target Groups → Select → Actions → Delete

3. **Terminate EC2 Instance:**
   - EC2 Console → Instances → Select → Instance State → Terminate

4. **Delete RDS Instance:**
   - RDS Console → Databases → Select → Actions → Delete
   - Uncheck "Create final snapshot" (we don't need it for learning)
   - Type the confirmation text
   - Delete

5. **Delete Security Groups:**
   - Wait 5 minutes for resources to finish deleting
   - EC2 Console → Security Groups
   - Delete: sockshop-alb-sg, sockshop-ec2-sg, sockshop-rds-sg
   - (Do NOT delete the default security group)

6. **Delete VPC:**
   - VPC Console → Your VPCs → Select sockshop-vpc
   - Actions → Delete VPC
   - This deletes the VPC, subnets, route tables, internet gateway (all of it)

7. **Delete Key Pair:**
   - EC2 Console → Key Pairs → Select → Actions → Delete
   - Also delete the .pem file from your computer

8. **Verify in Billing:**
   - Wait 24 hours
   - Check Billing Dashboard
   - Should show $0.50 or less for the day

### Option 3: Use a Cleanup Script

Save this script for quick cleanup:

```bash
#!/bin/bash
# cleanup-day1.sh

echo "Starting cleanup..."

# Get resource IDs (replace with yours)
INSTANCE_ID="i-1234567890abcdef0"
DB_INSTANCE="sockshop-db"
ALB_ARN="arn:aws:elasticloadbalancing:..."
TARGET_GROUP_ARN="arn:aws:elasticloadbalancing:..."
VPC_ID="vpc-1234567890abcdef0"

# Delete in order
echo "Deleting ALB..."
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN

echo "Deleting Target Group..."
aws elbv2 delete-target-group --target-group-arn $TARGET_GROUP_ARN

echo "Terminating EC2 instance..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

echo "Deleting RDS instance..."
aws rds delete-db-instance --db-instance-identifier $DB_INSTANCE --skip-final-snapshot

echo "Waiting for resources to delete (this takes 5-10 minutes)..."
sleep 300

echo "Deleting VPC (includes subnets, route tables, IGW)..."
aws ec2 delete-vpc --vpc-id $VPC_ID

echo "Cleanup complete! Check billing in 24 hours."
```

Make it executable:
```bash
chmod +x cleanup-day1.sh
```

## What's Next?

Tomorrow (Day 2), we're going to take everything we did today and **automate it completely with Terraform**.

We'll write code that creates:
- The entire VPC with subnets
- The EC2 instance with Docker pre-installed
- The RDS database with the right configuration
- The Application Load Balancer with target groups
- All security groups with correct rules
- CloudWatch alarms and dashboards

And we'll be able to run it all with:
```bash
terraform apply
```

In 5 minutes, everything we spent 7 hours doing today will be done.

That's the power of Infrastructure as Code.

**But here's the thing:** Tomorrow will be easy because you understand what's happening today. You know what a VPC is. You know why security groups matter. You know the pain of clicking through the console.

Tomorrow, you'll appreciate every line of Terraform code.

## Key Takeaways from Day 1

**Technical Skills Gained:**
- ✅ Created and configured an AWS account with proper security (MFA, IAM)
- ✅ Built a custom VPC with public and private subnets across multiple AZs
- ✅ Launched and configured EC2 instances
- ✅ Deployed a multi-container application with Docker Compose
- ✅ Set up RDS MySQL in a private subnet
- ✅ Configured Application Load Balancer with health checks
- ✅ Created CloudWatch dashboards and alarms
- ✅ Implemented proper security groups (defense in depth)
- ✅ Set up cost monitoring and billing alerts

**Conceptual Understanding:**
- 🧠 AWS networking fundamentals (VPC, subnets, routing, security groups)
- 🧠 The difference between public and private subnets
- 🧠 How load balancers enable high availability and scaling
- 🧠 Why managed services (RDS) are worth using in production
- 🧠 The importance of monitoring and alerting
- 🧠 AWS Free Tier limits and cost management

**Production Mindset:**
- 💡 Always enable MFA and use IAM users, never root
- 💡 Tag everything from day one for cost tracking
- 💡 Set up billing alerts before launching any resources
- 💡 Use separate security groups for each layer
- 💡 Deploy across multiple AZs for high availability
- 💡 Monitor costs daily when learning

**What You Can Do Now:**
You can deploy a production-grade (well, almost) multi-tier application on AWS. You understand the building blocks. You can explain what each component does and why it exists.

Tomorrow, we make you dangerous with automation.

## Resources

**AWS Documentation:**
- [VPC User Guide](https://docs.aws.amazon.com/vpc/)
- [EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [RDS User Guide](https://docs.aws.amazon.com/rds/)
- [ELB User Guide](https://docs.aws.amazon.com/elasticloadbalancing/)

**Sock Shop:**
- [GitHub Repository](https://github.com/microservices-demo/microservices-demo)
- [Architecture Diagram](https://microservices-demo.github.io/)

**Cost Management:**
- [AWS Free Tier](https://aws.amazon.com/free/)
- [AWS Cost Calculator](https://calculator.aws/)
- [Cost Optimization Guide](https://docs.aws.amazon.com/cost-management/)

**My Content:**
- [Day 2: Terraform IaC](link-coming-tomorrow)
- [Linux Fundamentals](https://devopsengineers.in/docs/category/linux)
- [Shell Scripting](https://devopsengineers.in/docs/category/shell-scripting)

---

**Time to be honest with you.**

Today was long. It was tedious. You probably made mistakes. You probably had to backtrack. You might have gotten frustrated when something didn't work.

Good.

That's real learning. That's how you build the muscle memory that saves you when things break at 2 AM in production.

I've been doing this for 6 years. I still refer to documentation. I still make mistakes. I still learn new things every day.

The difference is: I know what I'm looking for. I know how the pieces fit together. I know what's normal and what's wrong.

After today, so do you.

Get some rest. Hydrate. Tomorrow we automate this entire thing.

See you in Day 2.

-Koti

---

**Questions?** Open an issue on the [GitHub repository](link).
**Found this helpful?** Star the repo and share it with someone learning DevOps.
**Want to support this work?** Just use it and learn. That's enough.
