#!/bin/bash

###############################################################################
# Day 1 Cleanup Script - Sock Shop AWS Infrastructure
#
# This script deletes all resources created in Day 1 to avoid ongoing costs.
# Run this when you're done for the day or want a clean slate.
#
# Author: Koti
# Date: 2025-12-28
# Cost Impact: Saves ~$0.50/day (ALB cost)
###############################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration - UPDATE THESE WITH YOUR VALUES
AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_TAG="SockShop"

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}\n"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

confirm_deletion() {
    echo -e "${RED}⚠️  WARNING: This will DELETE all Day 1 resources!${NC}"
    echo -e "${YELLOW}This includes:${NC}"
    echo "  - Application Load Balancer (~\$0.50/day savings)"
    echo "  - EC2 instances and all data on them"
    echo "  - RDS database and all data in it"
    echo "  - VPC and all networking components"
    echo ""
    echo -e "${RED}This action CANNOT be undone!${NC}"
    echo ""
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirmation

    if [ "$confirmation" != "yes" ]; then
        echo -e "${YELLOW}Cleanup cancelled.${NC}"
        exit 0
    fi
}

###############################################################################
# Resource Discovery Functions
###############################################################################

get_vpc_id() {
    aws ec2 describe-vpcs \
        --region "$AWS_REGION" \
        --filters "Name=tag:Name,Values=sockshop-vpc" \
        --query 'Vpcs[0].VpcId' \
        --output text 2>/dev/null || echo ""
}

get_alb_arn() {
    aws elbv2 describe-load-balancers \
        --region "$AWS_REGION" \
        --query "LoadBalancers[?contains(LoadBalancerName, 'sockshop-alb')].LoadBalancerArn" \
        --output text 2>/dev/null || echo ""
}

get_target_group_arn() {
    aws elbv2 describe-target-groups \
        --region "$AWS_REGION" \
        --query "TargetGroups[?contains(TargetGroupName, 'sockshop-tg')].TargetGroupArn" \
        --output text 2>/dev/null || echo ""
}

get_ec2_instances() {
    aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --filters "Name=tag:Project,Values=$PROJECT_TAG" "Name=instance-state-name,Values=running,stopped,stopping" \
        --query 'Reservations[*].Instances[*].InstanceId' \
        --output text 2>/dev/null || echo ""
}

get_rds_instances() {
    aws rds describe-db-instances \
        --region "$AWS_REGION" \
        --query "DBInstances[?contains(DBInstanceIdentifier, 'sockshop')].DBInstanceIdentifier" \
        --output text 2>/dev/null || echo ""
}

get_security_groups() {
    local vpc_id=$1
    aws ec2 describe-security-groups \
        --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=group-name,Values=sockshop-*" \
        --query 'SecurityGroups[*].GroupId' \
        --output text 2>/dev/null || echo ""
}

###############################################################################
# Deletion Functions
###############################################################################

delete_alb() {
    local alb_arn=$1

    if [ -z "$alb_arn" ]; then
        print_info "No ALB found to delete"
        return 0
    fi

    print_info "Deleting Application Load Balancer..."
    if aws elbv2 delete-load-balancer --region "$AWS_REGION" --load-balancer-arn "$alb_arn" 2>/dev/null; then
        print_success "ALB deletion initiated"
        print_info "Waiting for ALB to be fully deleted (this takes 2-3 minutes)..."
        sleep 180  # Wait for ALB to be deleted before proceeding
    else
        print_error "Failed to delete ALB"
    fi
}

delete_target_group() {
    local tg_arn=$1

    if [ -z "$tg_arn" ]; then
        print_info "No target group found to delete"
        return 0
    fi

    print_info "Deleting Target Group..."
    # Need to wait a bit after ALB deletion before target group can be deleted
    sleep 30

    if aws elbv2 delete-target-group --region "$AWS_REGION" --target-group-arn "$tg_arn" 2>/dev/null; then
        print_success "Target group deleted"
    else
        print_error "Failed to delete target group (may already be deleted)"
    fi
}

delete_ec2_instances() {
    local instance_ids=$1

    if [ -z "$instance_ids" ]; then
        print_info "No EC2 instances found to delete"
        return 0
    fi

    print_info "Terminating EC2 instances: $instance_ids"
    if aws ec2 terminate-instances --region "$AWS_REGION" --instance-ids $instance_ids >/dev/null 2>&1; then
        print_success "EC2 instance termination initiated"
        print_info "Waiting for instances to terminate (this takes 1-2 minutes)..."
        aws ec2 wait instance-terminated --region "$AWS_REGION" --instance-ids $instance_ids 2>/dev/null || true
        print_success "EC2 instances terminated"
    else
        print_error "Failed to terminate EC2 instances"
    fi
}

delete_rds_instances() {
    local db_instances=$1

    if [ -z "$db_instances" ]; then
        print_info "No RDS instances found to delete"
        return 0
    fi

    for db_id in $db_instances; do
        print_info "Deleting RDS instance: $db_id"
        if aws rds delete-db-instance \
            --region "$AWS_REGION" \
            --db-instance-identifier "$db_id" \
            --skip-final-snapshot \
            --delete-automated-backups 2>/dev/null; then
            print_success "RDS deletion initiated for $db_id"
        else
            print_error "Failed to delete RDS instance $db_id"
        fi
    done

    # RDS deletion is async, wait a bit before proceeding
    if [ -n "$db_instances" ]; then
        print_info "Waiting for RDS instances to be deleted (this takes 5-10 minutes)..."
        for db_id in $db_instances; do
            aws rds wait db-instance-deleted --region "$AWS_REGION" --db-instance-identifier "$db_id" 2>/dev/null || true
        done
        print_success "RDS instances deleted"
    fi
}

delete_security_groups() {
    local sg_ids=$1

    if [ -z "$sg_ids" ]; then
        print_info "No security groups found to delete"
        return 0
    fi

    # Wait a bit for resources using the security groups to be fully deleted
    sleep 60

    print_info "Deleting security groups..."
    for sg_id in $sg_ids; do
        # Try to delete, but don't fail if it's still in use
        if aws ec2 delete-security-group --region "$AWS_REGION" --group-id "$sg_id" 2>/dev/null; then
            print_success "Deleted security group: $sg_id"
        else
            print_error "Could not delete security group $sg_id (may still be in use)"
        fi
    done
}

delete_vpc() {
    local vpc_id=$1

    if [ -z "$vpc_id" ]; then
        print_info "No VPC found to delete"
        return 0
    fi

    print_info "Deleting VPC and associated resources..."

    # Delete NAT Gateways if any
    local nat_gateways=$(aws ec2 describe-nat-gateways \
        --region "$AWS_REGION" \
        --filter "Name=vpc-id,Values=$vpc_id" "Name=state,Values=available" \
        --query 'NatGateways[*].NatGatewayId' \
        --output text 2>/dev/null || echo "")

    if [ -n "$nat_gateways" ]; then
        print_info "Deleting NAT Gateways..."
        for nat_id in $nat_gateways; do
            aws ec2 delete-nat-gateway --region "$AWS_REGION" --nat-gateway-id "$nat_id" 2>/dev/null || true
        done
        sleep 60  # Wait for NAT gateways to delete
    fi

    # Delete Internet Gateway
    local igw_id=$(aws ec2 describe-internet-gateways \
        --region "$AWS_REGION" \
        --filters "Name=attachment.vpc-id,Values=$vpc_id" \
        --query 'InternetGateways[0].InternetGatewayId' \
        --output text 2>/dev/null || echo "")

    if [ -n "$igw_id" ] && [ "$igw_id" != "None" ]; then
        print_info "Detaching and deleting Internet Gateway..."
        aws ec2 detach-internet-gateway --region "$AWS_REGION" --internet-gateway-id "$igw_id" --vpc-id "$vpc_id" 2>/dev/null || true
        aws ec2 delete-internet-gateway --region "$AWS_REGION" --internet-gateway-id "$igw_id" 2>/dev/null || true
    fi

    # Delete subnets
    local subnets=$(aws ec2 describe-subnets \
        --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'Subnets[*].SubnetId' \
        --output text 2>/dev/null || echo "")

    if [ -n "$subnets" ]; then
        print_info "Deleting subnets..."
        for subnet_id in $subnets; do
            aws ec2 delete-subnet --region "$AWS_REGION" --subnet-id "$subnet_id" 2>/dev/null || true
        done
    fi

    # Delete route tables (except main)
    local route_tables=$(aws ec2 describe-route-tables \
        --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'RouteTables[?Associations[0].Main==`false`].RouteTableId' \
        --output text 2>/dev/null || echo "")

    if [ -n "$route_tables" ]; then
        print_info "Deleting route tables..."
        for rt_id in $route_tables; do
            aws ec2 delete-route-table --region "$AWS_REGION" --route-table-id "$rt_id" 2>/dev/null || true
        done
    fi

    # Finally, delete the VPC
    sleep 30  # Give AWS time to clean up dependencies
    if aws ec2 delete-vpc --region "$AWS_REGION" --vpc-id "$vpc_id" 2>/dev/null; then
        print_success "VPC deleted"
    else
        print_error "Failed to delete VPC (may have remaining dependencies)"
        print_info "Try running this script again in a few minutes"
    fi
}

delete_key_pair() {
    print_info "Checking for SSH key pair..."
    local key_name="sockshop-key"

    if aws ec2 describe-key-pairs --region "$AWS_REGION" --key-names "$key_name" >/dev/null 2>&1; then
        print_info "Deleting key pair: $key_name"
        aws ec2 delete-key-pair --region "$AWS_REGION" --key-name "$key_name" 2>/dev/null || true
        print_success "Key pair deleted from AWS"
        print_info "Remember to also delete the local .pem file from your computer"
    else
        print_info "No key pair found to delete"
    fi
}

###############################################################################
# Main Execution
###############################################################################

main() {
    print_header "AWS Day 1 Cleanup Script"

    # Confirm deletion
    confirm_deletion

    print_info "Starting cleanup in region: $AWS_REGION"
    print_info "Project tag: $PROJECT_TAG"
    echo ""

    # Discover resources
    print_header "Step 1: Discovering Resources"

    VPC_ID=$(get_vpc_id)
    ALB_ARN=$(get_alb_arn)
    TG_ARN=$(get_target_group_arn)
    EC2_INSTANCES=$(get_ec2_instances)
    RDS_INSTANCES=$(get_rds_instances)

    print_info "VPC ID: ${VPC_ID:-Not found}"
    print_info "ALB ARN: ${ALB_ARN:-Not found}"
    print_info "Target Group ARN: ${TG_ARN:-Not found}"
    print_info "EC2 Instances: ${EC2_INSTANCES:-Not found}"
    print_info "RDS Instances: ${RDS_INSTANCES:-Not found}"

    # Delete resources in order
    print_header "Step 2: Deleting Load Balancer"
    delete_alb "$ALB_ARN"

    print_header "Step 3: Deleting Target Group"
    delete_target_group "$TG_ARN"

    print_header "Step 4: Terminating EC2 Instances"
    delete_ec2_instances "$EC2_INSTANCES"

    print_header "Step 5: Deleting RDS Instances"
    delete_rds_instances "$RDS_INSTANCES"

    print_header "Step 6: Deleting Security Groups"
    if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
        SG_IDS=$(get_security_groups "$VPC_ID")
        delete_security_groups "$SG_IDS"
    fi

    print_header "Step 7: Deleting VPC and Networking"
    delete_vpc "$VPC_ID"

    print_header "Step 8: Deleting Key Pair"
    delete_key_pair

    # Summary
    print_header "Cleanup Complete!"

    echo -e "${GREEN}All Day 1 resources have been deleted.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Check AWS Console to verify everything is deleted"
    echo "  2. Check Billing Dashboard in 24 hours to confirm \$0 cost"
    echo "  3. Delete local key file: rm ~/Downloads/sockshop-key.pem"
    echo ""
    echo "Cost savings: ~\$0.50/day (ALB cost eliminated)"
    echo ""
    echo -e "${YELLOW}Note: It may take a few minutes for all resources to be fully deleted.${NC}"
    echo -e "${YELLOW}If you see any errors above, wait 5 minutes and run this script again.${NC}"
}

# Run main function
main

###############################################################################
# End of Script
###############################################################################
