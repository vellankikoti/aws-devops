# Day 2: Infrastructure as Code with Terraform

**Theme: "Automate Everything You Did Yesterday"**

**Time:** 7-8 hours | **Cost:** ~$0.50/day | **Level:** Intermediate

---

## My Take: Why IaC Changed Everything

Yesterday, you spent hours clicking through the AWS Console, creating VPCs, launching EC2 instances, setting up RDS, configuring load balancers. Remember how tedious that was?

Now imagine doing that for 50 environments. Or imagine your colleague asking "Can you set up the same thing in us-west-2?" Or worse - imagine your infrastructure goes down and you need to recreate everything from scratch.

That's exactly what happened to us at TransUnion. We had a critical environment that was set up manually by an engineer who left the company. When we needed to recreate it... nobody knew exactly how it was configured. It took us 3 days to reverse-engineer the setup. Three. Days.

That's when I truly understood Infrastructure as Code. It's not just automation - it's **documentation that actually works**. Your Terraform code IS your infrastructure documentation. And unlike a wiki that nobody updates, your Terraform code is ALWAYS accurate because it's what actually creates the infrastructure.

Today, we're going to take EVERYTHING you built manually yesterday and codify it with Terraform. By end of today, you'll be able to create and destroy your entire AWS infrastructure in under 5 minutes.

---

## What You'll Build Today

```
┌──────────────────────────────────────────────────────────────────┐
│                     Terraform Managed Infrastructure             │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    VPC (10.0.0.0/16)                        │ │
│  │  ┌──────────────┐  ┌──────────────┐                        │ │
│  │  │Public Subnet │  │Public Subnet │  ← Internet Gateway    │ │
│  │  │  10.0.1.0/24 │  │  10.0.2.0/24 │                        │ │
│  │  │  ┌────────┐  │  │              │                        │ │
│  │  │  │  EC2   │  │  │   ┌──────┐   │                        │ │
│  │  │  │SockShop│  │  │   │ ALB  │   │                        │ │
│  │  │  └────────┘  │  │   └──────┘   │                        │ │
│  │  └──────────────┘  └──────────────┘                        │ │
│  │  ┌──────────────┐  ┌──────────────┐                        │ │
│  │  │Private Subnet│  │Private Subnet│                        │ │
│  │  │  10.0.3.0/24 │  │  10.0.4.0/24 │                        │ │
│  │  │  ┌────────┐  │  │  ┌────────┐  │                        │ │
│  │  │  │  RDS   │  │  │  │RDS Stby│  │                        │ │
│  │  │  │ MySQL  │  │  │  │(Multi) │  │                        │ │
│  │  │  └────────┘  │  │  └────────┘  │                        │ │
│  │  └──────────────┘  └──────────────┘                        │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ S3 State │  │  DynamoDB    │  │  CloudWatch  │              │
│  │  Bucket  │  │ State Lock   │  │   Alarms     │              │
│  └──────────┘  └──────────────┘  └──────────────┘              │
└──────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

Before starting Day 2, ensure:
- ✅ Day 1 completed (understand VPC, EC2, RDS, ALB concepts)
- ✅ AWS CLI configured (`aws sts get-caller-identity` works)
- ✅ Day 1 resources cleaned up (we're recreating everything with Terraform)

---

## Morning Session: Terraform Fundamentals (2 hours)

### Step 1: Install Terraform

```bash
# Download and install Terraform
# Check latest version at https://releases.hashicorp.com/terraform/

# Linux/WSL
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform_1.6.6_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

# Mac (with Homebrew)
# brew install terraform
```

**Verify installation:**
```bash
terraform --version
# Terraform v1.6.6
```

### Step 2: Understand Terraform Basics

**HCL (HashiCorp Configuration Language) - The Terraform Language:**

```hcl
# This is a comment

# Resources are the building blocks
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"    # Free Tier eligible!

  tags = {
    Name = "MyInstance"
  }
}

# Variables make code reusable
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# Outputs display useful information
output "instance_ip" {
  value = aws_instance.example.public_ip
}
```

**The Terraform Workflow:**
```
terraform init    → Download providers and modules
terraform plan    → Preview what will change (DRY RUN)
terraform apply   → Create/modify infrastructure
terraform destroy → Delete everything
```

> **Production Tip from the Trenches:** At TransUnion, we NEVER run `terraform apply` without first reviewing `terraform plan`. We even pipe plan output to a PR for team review. The 5 minutes you spend reviewing a plan can save hours of debugging.

### Step 3: Your First Terraform Configuration

Create a workspace:
```bash
cd ~/aws-devops/day2-terraform
```

Let's start simple. We'll build up to the full infrastructure:

```hcl
# This is already in environments/dev/main.tf
# But let's understand it piece by piece
```

### Step 4: Understanding Providers

```hcl
# AWS Provider tells Terraform how to talk to AWS
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "SockShop"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Course      = "AWS-DevOps-7Days"
    }
  }
}
```

> **Why default_tags?** Every resource Terraform creates will automatically get these tags. This is CRITICAL for cost tracking and cleanup. I learned this the hard way when we had "mystery resources" in our AWS account that nobody could identify. Tags save lives (and money).

### Step 5: Understanding State

Terraform keeps track of what it has created in a "state file." This is like Terraform's memory.

```bash
# After terraform apply, you'll see:
# terraform.tfstate - THIS FILE IS CRITICAL
# It maps your .tf code to real AWS resources

# NEVER commit terraform.tfstate to git!
# It may contain secrets (database passwords, etc.)
```

**Local State vs Remote State:**
```
Local State (default):
  ✅ Simple, works out of the box
  ❌ Can't collaborate with team
  ❌ No locking (two people can corrupt state)
  ❌ Lost if your laptop dies

Remote State (what we'll set up):
  ✅ Stored in S3 (durable, versioned)
  ✅ Locked with DynamoDB (safe collaboration)
  ✅ Accessible by CI/CD pipelines
  ❌ Requires S3 bucket setup
```

---

## Interactive Exercise: Try This!

Before we build modules, try this quick experiment:

```bash
# Create a test directory
mkdir -p /tmp/terraform-test && cd /tmp/terraform-test

# Create a simple main.tf
cat > main.tf << 'EOF'
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "test" {
  bucket = "my-terraform-test-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}

output "bucket_name" {
  value = aws_s3_bucket.test.bucket
}
EOF

# Initialize and plan
terraform init
terraform plan

# See what Terraform WOULD do without doing it
# This is your safety net!
```

> **Challenge:** Can you add a tag to the S3 bucket? Can you add a `force_destroy = true` argument? Try it!

---

## Afternoon Session: Building Terraform Modules (3 hours)

### Understanding Modules

Modules are reusable packages of Terraform code. Think of them like functions in programming.

```
modules/
├── vpc/           # Network infrastructure
├── ec2/           # Compute instances
├── rds/           # Database
├── alb/           # Load balancer
└── security-groups/  # Firewall rules
```

Each module has three files:
- `main.tf` - The resources
- `variables.tf` - Input parameters
- `outputs.tf` - Return values

### Module 1: VPC Module

This creates the entire network foundation. Look at `modules/vpc/main.tf`:

```hcl
# The VPC is your private cloud within AWS
# Think of it as your own data center's network

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # Needed for RDS
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway - the door to the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}
```

> **Memory Technique:** VPC = Your apartment building. Subnets = Individual apartments. Internet Gateway = The main entrance. Route Tables = Hallway signs. Security Groups = Door locks.

### Module 2: Security Groups

Look at `modules/security-groups/main.tf`:

```hcl
# ALB Security Group - Allows HTTP/HTTPS from internet
# EC2 Security Group - Only allows traffic from ALB
# RDS Security Group - Only allows traffic from EC2

# This is the "chain of trust" pattern
# Internet → ALB → EC2 → RDS
# Each layer only trusts the one before it
```

### Module 3: EC2 Module

The EC2 module includes user_data to automatically install Docker and deploy Sock Shop:

```hcl
resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type  # t2.micro = Free Tier!

  user_data = templatefile("${path.module}/user_data.sh", {
    db_host = var.db_host
    db_port = var.db_port
  })
}
```

### Module 4: RDS Module

```hcl
resource "aws_db_instance" "main" {
  identifier           = "${var.project_name}-db"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.micro"  # Free Tier!
  allocated_storage   = 20             # Free Tier: 20GB

  # NEVER use these in production - use Secrets Manager
  username = var.db_username
  password = var.db_password

  skip_final_snapshot = true  # For learning only!
}
```

### Module 5: ALB Module

```hcl
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids
}
```

### Putting It All Together

The environment configuration (`environments/dev/main.tf`) wires all modules together:

```hcl
module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"
  # ...
}

module "security_groups" {
  source = "../../modules/security-groups"
  vpc_id = module.vpc.vpc_id
  # ...
}

module "ec2" {
  source    = "../../modules/ec2"
  subnet_id = module.vpc.public_subnet_ids[0]
  sg_id     = module.security_groups.ec2_sg_id
  # ...
}
```

> **Key Insight:** Notice how modules reference each other's outputs. `module.vpc.vpc_id` is the VPC module's output being used as input to the security groups module. This is how Terraform understands dependencies.

---

## Interactive Exercise: Deploy Your Infrastructure!

```bash
cd ~/aws-devops/day2-terraform/environments/dev

# 1. Initialize Terraform
terraform init

# 2. Review what will be created
terraform plan

# Look at the plan output carefully:
# - How many resources will be created?
# - What are the resource names?
# - Any surprises?

# 3. Apply the infrastructure
terraform apply

# Type "yes" when prompted
# Watch as Terraform creates everything in ~5 minutes!

# 4. Check your outputs
terraform output
```

> **Challenge:** After applying, go to the AWS Console and verify each resource exists. Compare with what you created manually on Day 1. Same result, but now it's code!

---

## Evening Session: State Management & Workspaces (2 hours)

### Setting Up Remote State

First, create the S3 bucket and DynamoDB table for state storage:

```bash
# Run the setup script
chmod +x ~/aws-devops/day2-terraform/scripts/setup-backend.sh
~/aws-devops/day2-terraform/scripts/setup-backend.sh
```

Then update your backend configuration:

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "sockshop-terraform-state-YOURACCOUNTID"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

```bash
# Migrate local state to S3
terraform init -migrate-state
```

### Terraform Workspaces

Workspaces let you manage multiple environments (dev/staging/prod) with the same code:

```bash
# List workspaces
terraform workspace list

# Create new workspaces
terraform workspace new staging
terraform workspace new prod

# Switch workspace
terraform workspace select dev

# Current workspace
terraform workspace show
```

```hcl
# Use workspace in your code
locals {
  environment = terraform.workspace

  instance_types = {
    dev     = "t2.micro"
    staging = "t2.small"
    prod    = "t2.medium"
  }
}

resource "aws_instance" "app" {
  instance_type = local.instance_types[local.environment]
}
```

### The Power of Destroy and Recreate

```bash
# Destroy EVERYTHING
terraform destroy
# Type "yes"

# Now recreate everything
terraform apply
# Type "yes"

# That's it. Your entire infrastructure, recreated in 5 minutes.
# Try doing THAT with manual setup!
```

> **Production Tip:** At TransUnion, our dev environments are destroyed every Friday night and recreated Monday morning. This saves ~60% on dev costs. Terraform makes this possible.

---

## Common Mistakes I Made (So You Don't Have To)

### 1. Committing .tfstate to Git
```bash
# WRONG - state contains secrets!
git add terraform.tfstate

# RIGHT - always have this in .gitignore
echo "*.tfstate*" >> .gitignore
echo ".terraform/" >> .gitignore
```

### 2. Not Using -auto-approve Carefully
```bash
# DANGEROUS in production
terraform apply -auto-approve

# SAFE approach
terraform plan -out=plan.tfplan
terraform apply plan.tfplan
```

### 3. Forgetting to Lock State
If two people run `terraform apply` at the same time without state locking, you'll corrupt your state. Always use DynamoDB locking with remote state.

### 4. Hardcoding Values
```hcl
# WRONG
resource "aws_instance" "app" {
  instance_type = "t2.micro"
  ami           = "ami-12345"
}

# RIGHT
resource "aws_instance" "app" {
  instance_type = var.instance_type
  ami           = data.aws_ami.amazon_linux.id
}
```

### 5. Not Using Data Sources
```hcl
# Instead of hardcoding AMI IDs (which change by region):
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

---

## Production Tips from the Trenches

1. **Always use `terraform plan` before `apply`** - Review changes like you review code
2. **Use modules from Day 1** - Don't repeat yourself
3. **Tag everything** - You'll thank yourself during cost analysis
4. **Use `prevent_destroy`** for critical resources like databases
5. **Version your modules** - Use Git tags for module versions
6. **Use `terraform fmt`** - Consistent formatting across team
7. **Use `terraform validate`** - Catch syntax errors early

---

## Cost Breakdown

| Resource | Cost | Notes |
|----------|------|-------|
| EC2 t2.micro | $0.00 | Free Tier (750 hrs/month) |
| RDS db.t3.micro | $0.00 | Free Tier (750 hrs/month) |
| ALB | ~$0.50/day | Not in Free Tier |
| S3 (state) | $0.00 | < 5GB free |
| DynamoDB (lock) | $0.00 | Free Tier |
| EBS 30GB | $0.00 | Free Tier |
| **Total** | **~$0.50/day** | |

---

## Deeper Learning Resources

- [HashiCorp Learn - Terraform AWS](https://github.com/hashicorp/learn-terraform-aws-instance) - Official tutorial
- [Terraform AWS Modules](https://github.com/terraform-aws-modules) - Production-ready community modules
- [Terraform Best Practices](https://www.terraform-best-practices.com/) - Community guide

---

## Troubleshooting

### "Error: No valid credential sources found"
```bash
aws sts get-caller-identity  # Check your AWS credentials
aws configure                # Reconfigure if needed
```

### "Error: Error acquiring the state lock"
```bash
# Someone else (or a crashed process) holds the lock
terraform force-unlock LOCK_ID
```

### "Error: Error creating VPC: VpcLimitExceeded"
```bash
# You've hit the VPC limit (default: 5 per region)
# Delete unused VPCs or request a limit increase
aws ec2 describe-vpcs --query 'Vpcs[*].VpcId'
```

### "Error: InvalidParameterValue: Address X.X.X.X does not fall within the subnet"
Check your CIDR blocks. Subnets must be within the VPC CIDR range.

---

## What's Next?

Tomorrow (Day 3), we'll use **Ansible** to configure these servers. Terraform creates the infrastructure, Ansible configures it. They're the perfect pair.

Think of it this way:
- **Terraform** = Building the house (walls, roof, plumbing)
- **Ansible** = Furnishing the house (installing software, configuring services)

---

## Cleanup

```bash
# Option 1: Destroy with Terraform (recommended)
cd ~/aws-devops/day2-terraform/environments/dev
terraform destroy

# Option 2: Use cleanup script
chmod +x ~/aws-devops/day2-terraform/scripts/cleanup-day2.sh
~/aws-devops/day2-terraform/scripts/cleanup-day2.sh
```

> **Remember:** Always clean up if you're done for the day. Even $0.50/day adds up!

---

**You did it!** You just automated an entire AWS infrastructure. What took you 4+ hours manually on Day 1, now takes 5 minutes with code. That's the power of Terraform.

-Koti
