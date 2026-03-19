# RDS Database Setup - Detailed Guide

## What We're Building

A managed MySQL database on AWS RDS:
- **Engine**: MySQL 8.0
- **Instance**: db.t3.micro (Free Tier eligible)
- **Storage**: 20 GB General Purpose SSD
- **Location**: Private subnet (not accessible from internet)
- **Access**: Only from our EC2 instance's security group

## Why RDS Instead of Docker Containers?

Sock Shop already runs databases in Docker containers. So why set up RDS?

| Feature | Docker Database | RDS |
|---------|----------------|-----|
| Automated backups | No | Yes (configurable) |
| Automated patching | No | Yes |
| High availability (Multi-AZ) | Manual setup | One checkbox |
| Point-in-time recovery | No | Yes (up to 5 min) |
| Performance insights | No | Yes |
| Data survives instance termination | No (unless volumes configured) | Yes |
| Maintenance | You manage everything | AWS manages it |

**Bottom line**: For production, always use managed databases. You focus on your application, AWS handles the infrastructure.

## Prerequisites

- [ ] VPC with private subnets created ([02-vpc-setup.md](./02-vpc-setup.md))
- [ ] EC2 instance running ([03-ec2-setup.md](./03-ec2-setup.md))
- [ ] You know your VPC ID and private subnet IDs

## Step 1: Create DB Subnet Group

RDS needs to know which subnets it can use. We use private subnets for security.

### Via Console

1. Navigate to **RDS Console** (search "RDS")
2. In left sidebar, click **"Subnet groups"**
3. Click **"Create DB subnet group"**
4. Settings:
   - **Name**: `sockshop-db-subnet-group`
   - **Description**: `Subnet group for Sock Shop databases`
   - **VPC**: Select `sockshop-vpc`
5. **Add subnets**:
   - Select both Availability Zones (e.g., us-east-1a and us-east-1b)
   - Select your **private** subnets (10.0.3.0/24 and 10.0.4.0/24)
6. Click **"Create"**

### Via CLI

```bash
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=sockshop-vpc" \
  --query 'Vpcs[0].VpcId' --output text)

# Get private subnet IDs
PRIV_SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=*private*" \
  --query 'Subnets[*].SubnetId' --output text)

aws rds create-db-subnet-group \
  --db-subnet-group-name sockshop-db-subnet-group \
  --db-subnet-group-description "Subnet group for Sock Shop databases" \
  --subnet-ids $PRIV_SUBNETS

echo "DB Subnet Group created"
```

## Step 2: Create Security Group for RDS

This security group ensures only our EC2 instances can reach the database.

### Via Console

1. Navigate to **EC2 Console → Security Groups**
2. Click **"Create security group"**
3. Settings:
   - **Name**: `sockshop-rds-sg`
   - **Description**: `Security group for Sock Shop RDS database`
   - **VPC**: `sockshop-vpc`
4. **Inbound Rules** - Add rule:

| Type | Port | Source | Description |
|------|------|--------|-------------|
| MySQL/Aurora | 3306 | sockshop-ec2-sg (select the security group) | MySQL from EC2 |

**Important**: For Source, select "Custom" and type `sockshop-ec2-sg` to reference the security group by name. This is more secure than using IP addresses because:
- It automatically allows any instance with that security group
- If you add more EC2 instances later, they automatically get access
- No hardcoded IP addresses to maintain

5. **Outbound Rules**: Leave default
6. Add tag: `Key=Project, Value=SockShop`
7. Click **"Create security group"**

### Via CLI

```bash
# Get EC2 security group ID
EC2_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=sockshop-ec2-sg" \
  --query 'SecurityGroups[0].GroupId' --output text)

# Create RDS security group
RDS_SG=$(aws ec2 create-security-group \
  --group-name sockshop-rds-sg \
  --description "Security group for Sock Shop RDS database" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

# Allow MySQL from EC2 security group
aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG \
  --protocol tcp --port 3306 \
  --source-group $EC2_SG

# Tag it
aws ec2 create-tags --resources $RDS_SG \
  --tags Key=Project,Value=SockShop Key=Name,Value=sockshop-rds-sg

echo "RDS Security Group: $RDS_SG"
```

## Step 3: Create RDS MySQL Instance

### Via Console

1. Navigate to **RDS Console → Databases**
2. Click **"Create database"**
3. Configuration:

| Setting | Value | Notes |
|---------|-------|-------|
| Creation method | Standard create | More control |
| Engine type | MySQL | |
| Engine version | MySQL 8.0.x (latest) | |
| Template | **Free tier** | Limits to free tier options |
| DB instance identifier | `sockshop-db` | Unique name |
| Master username | `admin` | |
| Master password | Your strong password | Write it down! |
| DB instance class | db.t3.micro | Auto-selected by Free tier |
| Storage type | General Purpose SSD (gp3) | |
| Allocated storage | 20 GB | Minimum |
| Storage autoscaling | **Uncheck** | Can cost money |
| VPC | `sockshop-vpc` | |
| DB subnet group | `sockshop-db-subnet-group` | |
| Public access | **No** | Critical for security |
| Security group | `sockshop-rds-sg` | |
| AZ | No preference | |
| Database authentication | Password | |
| Initial database name | `socksdb` | Under "Additional configuration" |
| Automated backups | Uncheck for Free Tier | Saves storage |
| Encryption | Uncheck | Not available in Free tier |

4. Click **"Create database"**

### Via CLI

```bash
aws rds create-db-instance \
  --db-instance-identifier sockshop-db \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --engine-version 8.0 \
  --master-username admin \
  --master-user-password "YourStrongPassword123!" \
  --allocated-storage 20 \
  --storage-type gp3 \
  --db-subnet-group-name sockshop-db-subnet-group \
  --vpc-security-group-ids $RDS_SG \
  --db-name socksdb \
  --no-publicly-accessible \
  --backup-retention-period 0 \
  --no-multi-az \
  --tags Key=Project,Value=SockShop Key=Name,Value=sockshop-db

echo "RDS instance creation initiated (takes 5-10 minutes)..."
```

## Step 4: Wait for RDS to be Available

**This takes 5-10 minutes.** RDS is provisioning:
- A compute instance for the database server
- Storage volumes
- MySQL installation and configuration
- Network interfaces in your private subnets

### Monitor Progress

```bash
# Check status via CLI
aws rds describe-db-instances \
  --db-instance-identifier sockshop-db \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]' \
  --output text

# Wait until status is "available"
aws rds wait db-instance-available \
  --db-instance-identifier sockshop-db
echo "RDS is ready!"
```

Or check in the RDS Console - wait for status to change from "Creating" to "Available".

## Step 5: Get the RDS Endpoint

Once available:

```bash
# Get the endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier sockshop-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "RDS Endpoint: $RDS_ENDPOINT"
```

The endpoint looks like: `sockshop-db.abc123def456.us-east-1.rds.amazonaws.com`

**Save this** - you'll need it to connect from EC2.

## Step 6: Test Connection from EC2

SSH into your EC2 instance and connect to RDS:

```bash
# Install MySQL client if not already installed
# Ubuntu:
sudo apt-get install -y mysql-client

# Amazon Linux:
sudo yum install -y mysql

# Connect to RDS
mysql -h sockshop-db.abc123def456.us-east-1.rds.amazonaws.com -u admin -p
```

Enter your password when prompted. You should see the MySQL prompt:

```
mysql>
```

### Verify the Database

```sql
-- Show databases
SHOW DATABASES;

-- Use our database
USE socksdb;

-- Create a test table
CREATE TABLE connection_test (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test data
INSERT INTO connection_test (message) VALUES ('RDS connection from EC2 is working!');

-- Verify
SELECT * FROM connection_test;

-- Clean up test table
DROP TABLE connection_test;

-- Exit
EXIT;
```

If all commands work, your RDS database is fully functional and accessible from your EC2 instance.

## Step 7: Verify Network Security

Confirm the database is NOT accessible from the internet:

```bash
# From your LOCAL machine (not EC2), try to connect:
mysql -h sockshop-db.abc123def456.us-east-1.rds.amazonaws.com -u admin -p
# This should FAIL with a timeout - that's correct!
# The database is only accessible from within the VPC
```

## Troubleshooting

### Can't connect from EC2: "Connection timed out"

1. **Security group**: Does `sockshop-rds-sg` allow port 3306 from `sockshop-ec2-sg`?
2. **Subnet**: Is RDS in private subnets of the same VPC as EC2?
3. **DB status**: Is the RDS instance "available"?
4. **Endpoint**: Are you using the correct endpoint (not the instance ID)?

```bash
# Verify security group allows connection
aws ec2 describe-security-groups \
  --group-names sockshop-rds-sg \
  --query 'SecurityGroups[0].IpPermissions'
```

### "Access denied for user 'admin'"

- Double-check your password
- Ensure you're using the correct username (`admin`)
- Try resetting the password in RDS Console: Modify → New master password

### RDS instance stuck in "Creating" for >15 minutes

- This is usually normal for first-time creation
- Check RDS Console → Events tab for any error messages
- If it's been >30 minutes, there may be a service issue in your region

## Save Your Resource IDs

```
DB Instance ID:      sockshop-db
DB Endpoint:         ________________________________.rds.amazonaws.com
DB Port:             3306
DB Name:             socksdb
Master Username:     admin
Master Password:     (stored securely)
DB Subnet Group:     sockshop-db-subnet-group
RDS Security Group:  sg-________________
```

## What You Learned

- Managed databases vs self-managed (containers)
- DB subnet groups and why databases go in private subnets
- Security group references (SG-to-SG rules, not IP-based)
- RDS creation and connection workflow

## Next Step

We have compute (EC2) and data (RDS). Now let's add a load balancer for production-grade traffic management.

**Next**: [06-alb-setup.md](./06-alb-setup.md) - Configure Application Load Balancer

---

**Time spent**: ~15-20 minutes (plus 5-10 min wait for RDS creation)
**Cost so far**: $0 (RDS db.t3.micro is Free Tier)
**Resources created**: DB subnet group, RDS security group, RDS MySQL instance
