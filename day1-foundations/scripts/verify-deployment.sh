#!/bin/bash

###############################################################################
# Deployment Verification Script
#
# This script verifies that all Day 1 resources are properly deployed
# and healthy. Run this after completing the deployment.
#
# Author: Koti
# Date: 2025-12-28
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PASS="${GREEN}✓${NC}"
FAIL="${RED}✗${NC}"
WARN="${YELLOW}⚠${NC}"

AWS_REGION="${AWS_REGION:-us-east-1}"

print_header() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}\n"
}

print_check() {
    local status=$1
    local message=$2
    echo -e "$status $message"
}

check_aws_cli() {
    if aws sts get-caller-identity >/dev/null 2>&1; then
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
        print_check "$PASS" "AWS CLI configured"
        echo "    Account: $ACCOUNT_ID"
        echo "    User: $USER_ARN"
        return 0
    else
        print_check "$FAIL" "AWS CLI not configured"
        return 1
    fi
}

check_vpc() {
    local vpc_id=$(aws ec2 describe-vpcs \
        --region "$AWS_REGION" \
        --filters "Name=tag:Name,Values=sockshop-vpc" \
        --query 'Vpcs[0].VpcId' \
        --output text 2>/dev/null)

    if [ -n "$vpc_id" ] && [ "$vpc_id" != "None" ]; then
        print_check "$PASS" "VPC exists: $vpc_id"

        # Check subnets
        local subnet_count=$(aws ec2 describe-subnets \
            --region "$AWS_REGION" \
            --filters "Name=vpc-id,Values=$vpc_id" \
            --query 'length(Subnets)' \
            --output text 2>/dev/null)

        echo "    Subnets: $subnet_count (expected: 4)"

        if [ "$subnet_count" -eq 4 ]; then
            print_check "$PASS" "All subnets created"
        else
            print_check "$WARN" "Expected 4 subnets, found $subnet_count"
        fi

        return 0
    else
        print_check "$FAIL" "VPC not found (tag: sockshop-vpc)"
        return 1
    fi
}

check_security_groups() {
    local sg_names=("sockshop-ec2-sg" "sockshop-rds-sg" "sockshop-alb-sg")
    local all_found=true

    for sg_name in "${sg_names[@]}"; do
        local sg_id=$(aws ec2 describe-security-groups \
            --region "$AWS_REGION" \
            --filters "Name=group-name,Values=$sg_name" \
            --query 'SecurityGroups[0].GroupId' \
            --output text 2>/dev/null)

        if [ -n "$sg_id" ] && [ "$sg_id" != "None" ]; then
            print_check "$PASS" "Security Group: $sg_name ($sg_id)"
        else
            print_check "$FAIL" "Security Group not found: $sg_name"
            all_found=false
        fi
    done

    if [ "$all_found" = true ]; then
        return 0
    else
        return 1
    fi
}

check_ec2() {
    local instance_id=$(aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --filters "Name=tag:Project,Values=SockShop" "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text 2>/dev/null)

    if [ -n "$instance_id" ] && [ "$instance_id" != "None" ]; then
        local instance_type=$(aws ec2 describe-instances \
            --region "$AWS_REGION" \
            --instance-ids "$instance_id" \
            --query 'Reservations[0].Instances[0].InstanceType' \
            --output text 2>/dev/null)

        local public_ip=$(aws ec2 describe-instances \
            --region "$AWS_REGION" \
            --instance-ids "$instance_id" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text 2>/dev/null)

        print_check "$PASS" "EC2 instance running: $instance_id"
        echo "    Type: $instance_type"
        echo "    Public IP: $public_ip"

        if [ "$instance_type" != "t2.micro" ]; then
            print_check "$WARN" "Instance type is $instance_type (not Free Tier t2.micro)"
        fi

        # Check instance status
        local status=$(aws ec2 describe-instance-status \
            --region "$AWS_REGION" \
            --instance-ids "$instance_id" \
            --query 'InstanceStatuses[0].InstanceStatus.Status' \
            --output text 2>/dev/null)

        if [ "$status" = "ok" ]; then
            print_check "$PASS" "Instance status checks passed"
        else
            print_check "$WARN" "Instance status: $status (may still be initializing)"
        fi

        return 0
    else
        print_check "$FAIL" "No running EC2 instance found (tag: Project=SockShop)"
        return 1
    fi
}

check_rds() {
    local db_id=$(aws rds describe-db-instances \
        --region "$AWS_REGION" \
        --query "DBInstances[?contains(DBInstanceIdentifier, 'sockshop')].DBInstanceIdentifier" \
        --output text 2>/dev/null)

    if [ -n "$db_id" ]; then
        local db_status=$(aws rds describe-db-instances \
            --region "$AWS_REGION" \
            --db-instance-identifier "$db_id" \
            --query 'DBInstances[0].DBInstanceStatus' \
            --output text 2>/dev/null)

        local db_class=$(aws rds describe-db-instances \
            --region "$AWS_REGION" \
            --db-instance-identifier "$db_id" \
            --query 'DBInstances[0].DBInstanceClass' \
            --output text 2>/dev/null)

        local endpoint=$(aws rds describe-db-instances \
            --region "$AWS_REGION" \
            --db-instance-identifier "$db_id" \
            --query 'DBInstances[0].Endpoint.Address' \
            --output text 2>/dev/null)

        print_check "$PASS" "RDS instance: $db_id"
        echo "    Status: $db_status"
        echo "    Class: $db_class"
        echo "    Endpoint: ${endpoint:-Not available yet}"

        if [ "$db_status" != "available" ]; then
            print_check "$WARN" "RDS status is '$db_status' (may still be creating)"
        else
            print_check "$PASS" "RDS is available"
        fi

        if [ "$db_class" != "db.t3.micro" ]; then
            print_check "$WARN" "Instance class is $db_class (not Free Tier db.t3.micro)"
        fi

        return 0
    else
        print_check "$FAIL" "No RDS instance found (identifier contains 'sockshop')"
        return 1
    fi
}

check_alb() {
    local alb_arn=$(aws elbv2 describe-load-balancers \
        --region "$AWS_REGION" \
        --query "LoadBalancers[?contains(LoadBalancerName, 'sockshop-alb')].LoadBalancerArn" \
        --output text 2>/dev/null)

    if [ -n "$alb_arn" ]; then
        local alb_dns=$(aws elbv2 describe-load-balancers \
            --region "$AWS_REGION" \
            --load-balancer-arns "$alb_arn" \
            --query 'LoadBalancers[0].DNSName' \
            --output text 2>/dev/null)

        local alb_state=$(aws elbv2 describe-load-balancers \
            --region "$AWS_REGION" \
            --load-balancer-arns "$alb_arn" \
            --query 'LoadBalancers[0].State.Code' \
            --output text 2>/dev/null)

        print_check "$PASS" "Application Load Balancer exists"
        echo "    DNS: $alb_dns"
        echo "    State: $alb_state"

        if [ "$alb_state" != "active" ]; then
            print_check "$WARN" "ALB state is '$alb_state' (may still be provisioning)"
        else
            print_check "$PASS" "ALB is active"
        fi

        # Check target group health
        local tg_arn=$(aws elbv2 describe-target-groups \
            --region "$AWS_REGION" \
            --query "TargetGroups[?contains(TargetGroupName, 'sockshop-tg')].TargetGroupArn" \
            --output text 2>/dev/null)

        if [ -n "$tg_arn" ]; then
            local health=$(aws elbv2 describe-target-health \
                --region "$AWS_REGION" \
                --target-group-arn "$tg_arn" \
                --query 'TargetHealthDescriptions[0].TargetHealth.State' \
                --output text 2>/dev/null)

            echo "    Target Health: ${health:-No targets registered}"

            if [ "$health" = "healthy" ]; then
                print_check "$PASS" "Targets are healthy"
                echo ""
                echo -e "${GREEN}🎉 Application should be accessible at:${NC}"
                echo -e "${GREEN}   http://$alb_dns${NC}"
            elif [ "$health" = "unhealthy" ]; then
                print_check "$FAIL" "Targets are unhealthy - check security groups and application logs"
            else
                print_check "$WARN" "Target health: $health (may be initializing)"
            fi
        fi

        return 0
    else
        print_check "$FAIL" "No Application Load Balancer found"
        return 1
    fi
}

check_cloudwatch_alarms() {
    local alarm_count=$(aws cloudwatch describe-alarms \
        --region "$AWS_REGION" \
        --query "length(MetricAlarms[?contains(AlarmName, 'sockshop')])" \
        --output text 2>/dev/null)

    if [ "$alarm_count" -gt 0 ]; then
        print_check "$PASS" "CloudWatch alarms configured ($alarm_count)"

        # List alarms
        aws cloudwatch describe-alarms \
            --region "$AWS_REGION" \
            --query "MetricAlarms[?contains(AlarmName, 'sockshop')].[AlarmName,StateValue]" \
            --output text 2>/dev/null | while read alarm_name state; do
            echo "    $alarm_name: $state"
        done

        return 0
    else
        print_check "$WARN" "No CloudWatch alarms found (optional but recommended)"
        return 0
    fi
}

###############################################################################
# Main Execution
###############################################################################

print_header "Day 1 Deployment Verification"

echo "Region: $AWS_REGION"
echo "Project: Sock Shop"
echo ""

TOTAL_CHECKS=0
PASSED_CHECKS=0

run_check() {
    local check_name=$1
    local check_function=$2

    print_header "$check_name"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if $check_function; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
}

run_check "AWS CLI Configuration" check_aws_cli
run_check "VPC and Subnets" check_vpc
run_check "Security Groups" check_security_groups
run_check "EC2 Instance" check_ec2
run_check "RDS Database" check_rds
run_check "Application Load Balancer" check_alb
run_check "CloudWatch Alarms" check_cloudwatch_alarms

print_header "Summary"

echo "Checks Passed: $PASSED_CHECKS / $TOTAL_CHECKS"
echo ""

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    echo -e "${GREEN}🎉 All checks passed! Your Day 1 deployment is complete.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Access Sock Shop via the ALB DNS name (shown above)"
    echo "  2. Test the application (browse products, add to cart, checkout)"
    echo "  3. Monitor costs: ./check-costs.sh"
    echo "  4. When done, clean up: ./cleanup-day1.sh"
elif [ $PASSED_CHECKS -ge $((TOTAL_CHECKS * 2 / 3)) ]; then
    echo -e "${YELLOW}⚠️  Most checks passed, but some issues detected.${NC}"
    echo "Review the warnings above and fix any issues."
else
    echo -e "${RED}❌ Multiple checks failed. Review your deployment.${NC}"
    echo "Common issues:"
    echo "  - Resources still being created (wait a few minutes)"
    echo "  - Wrong region (check AWS_REGION environment variable)"
    echo "  - Typos in resource names or tags"
fi

echo ""
echo "For detailed troubleshooting, see: manual-steps/troubleshooting.md"
echo ""

###############################################################################
# End of Script
###############################################################################
