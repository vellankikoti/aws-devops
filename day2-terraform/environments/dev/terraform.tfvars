# =============================================================================
# Dev Environment Variables
# =============================================================================
# WARNING: Do NOT commit this file if it contains real passwords!
# Use terraform.tfvars.example and copy to terraform.tfvars locally

aws_region    = "us-east-1"
project_name  = "sockshop"
environment   = "dev"
vpc_cidr      = "10.0.0.0/16"
instance_type = "t2.micro"
key_pair_name = ""

# Database credentials - CHANGE THESE!
db_username = "admin"
db_password = "ChangeMe123!"

# Restrict SSH to your IP for security
# Find your IP: curl -s ifconfig.me
allowed_ssh_cidrs = ["0.0.0.0/0"]
