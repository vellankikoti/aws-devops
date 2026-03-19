# =============================================================================
# Dev Environment - Sock Shop Infrastructure
# =============================================================================

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
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Course      = "AWS-DevOps-7Days"
    }
  }
}

# --- VPC ---
module "vpc" {
  source             = "../../modules/vpc"
  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = false
}

# --- Security Groups ---
module "security_groups" {
  source            = "../../modules/security-groups"
  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}

# --- EC2 ---
module "ec2" {
  source            = "../../modules/ec2"
  project_name      = var.project_name
  instance_type     = var.instance_type
  key_pair_name     = var.key_pair_name
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.security_groups.ec2_sg_id
}

# --- RDS ---
module "rds" {
  source            = "../../modules/rds"
  project_name      = var.project_name
  environment       = var.environment
  instance_class    = var.db_instance_class
  database_username = var.db_username
  database_password = var.db_password
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_groups.rds_sg_id
  multi_az          = false
}

# --- ALB ---
module "alb" {
  source            = "../../modules/alb"
  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.alb_sg_id
  instance_id       = module.ec2.instance_id
}
