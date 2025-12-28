#!/bin/bash

###############################################################################
# Cost Monitoring Script - Check Your AWS Spending
#
# This script shows your current AWS costs and Free Tier usage.
# Run this daily to catch any unexpected charges.
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

print_header() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}\n"
}

print_info() {
    echo -e "${YELLOW}$1${NC}"
}

print_warning() {
    echo -e "${RED}⚠️  $1${NC}"
}

# Check if AWS CLI is configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo -e "${RED}Error: AWS CLI not configured or credentials invalid${NC}"
    echo "Run: aws configure"
    exit 1
fi

print_header "AWS Cost Monitor - Day 1 Learning Project"

# Get current month costs
print_info "📊 Month-to-Date Costs:"
echo ""

# Calculate start and end dates for current month
START_DATE=$(date -u +%Y-%m-01)
END_DATE=$(date -u +%Y-%m-%d)

# Get total cost for current month
TOTAL_COST=$(aws ce get-cost-and-usage \
    --time-period Start=${START_DATE},End=${END_DATE} \
    --granularity MONTHLY \
    --metrics UnblendedCost \
    --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
    --output text 2>/dev/null || echo "0")

# Round to 2 decimal places
TOTAL_COST=$(printf "%.2f" "$TOTAL_COST")

echo "Total Spend This Month: \$${TOTAL_COST}"
echo ""

# Check if over budget
if (( $(echo "$TOTAL_COST > 10" | bc -l) )); then
    print_warning "You're over \$10! Review your resources immediately."
elif (( $(echo "$TOTAL_COST > 5" | bc -l) )); then
    print_warning "Approaching \$10 budget. Check your running resources."
else
    echo -e "${GREEN}✓ Within budget ($TOTAL_COST / \$10 monthly)${NC}"
fi

echo ""

# Get costs by service
print_info "💰 Costs by Service (Top 5):"
echo ""

aws ce get-cost-and-usage \
    --time-period Start=${START_DATE},End=${END_DATE} \
    --granularity MONTHLY \
    --metrics UnblendedCost \
    --group-by Type=DIMENSION,Key=SERVICE \
    --query 'ResultsByTime[0].Groups[].[Keys[0],Metrics.UnblendedCost.Amount]' \
    --output text 2>/dev/null | \
    sort -k2 -rn | \
    head -5 | \
    while read service cost; do
        cost=$(printf "%.2f" "$cost")
        if (( $(echo "$cost > 0.01" | bc -l) )); then
            echo "  ${service}: \$${cost}"
        fi
    done

echo ""

# Expected costs for Day 1
print_info "📋 Expected Daily Costs for Day 1 Project:"
echo ""
echo "  EC2 t2.micro: \$0.00 (Free Tier - 750 hrs/month)"
echo "  RDS db.t3.micro: \$0.00 (Free Tier - 750 hrs/month)"
echo "  EBS 30GB: \$0.00 (Free Tier)"
echo "  Application Load Balancer: ~\$0.50/day"
echo "  Data Transfer: \$0.00 (Free Tier - 15GB/month)"
echo ""
echo "  Expected Daily Cost: ~\$0.50"
echo "  Expected Weekly Cost (7 days): ~\$3.50"
echo ""

# Check running EC2 instances
print_info "🖥️  Running EC2 Instances:"
echo ""

RUNNING_INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,Tags[?Key==`Name`].Value|[0],LaunchTime]' \
    --output text 2>/dev/null || echo "")

if [ -z "$RUNNING_INSTANCES" ]; then
    echo "  No running instances (cost: \$0)"
else
    echo "$RUNNING_INSTANCES" | while read instance_id instance_type name launch_time; do
        # Calculate hours running
        launch_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${launch_time%.000Z}" "+%s" 2>/dev/null || echo "0")
        current_epoch=$(date +%s)
        hours_running=$(( (current_epoch - launch_epoch) / 3600 ))

        echo "  ${name:-Unnamed} ($instance_type)"
        echo "    ID: $instance_id"
        echo "    Running for: ${hours_running} hours"

        # Warn if not Free Tier eligible
        if [[ "$instance_type" != "t2.micro" ]]; then
            print_warning "    Not Free Tier eligible! (t2.micro is free)"
        fi
        echo ""
    done
fi

# Check running RDS instances
print_info "🗄️  Running RDS Instances:"
echo ""

RUNNING_DBS=$(aws rds describe-db-instances \
    --query 'DBInstances[?DBInstanceStatus==`available`].[DBInstanceIdentifier,DBInstanceClass,InstanceCreateTime]' \
    --output text 2>/dev/null || echo "")

if [ -z "$RUNNING_DBS" ]; then
    echo "  No running databases (cost: \$0)"
else
    echo "$RUNNING_DBS" | while read db_id db_class create_time; do
        echo "  $db_id ($db_class)"

        if [[ "$db_class" != "db.t3.micro" ]] && [[ "$db_class" != "db.t2.micro" ]]; then
            print_warning "    Not Free Tier eligible! (db.t3.micro is free)"
        fi
        echo ""
    done
fi

# Check Application Load Balancers
print_info "⚖️  Load Balancers:"
echo ""

ALBS=$(aws elbv2 describe-load-balancers \
    --query 'LoadBalancers[*].[LoadBalancerName,Type,CreatedTime]' \
    --output text 2>/dev/null || echo "")

if [ -z "$ALBS" ]; then
    echo "  No load balancers (cost: \$0)"
else
    ALB_COUNT=$(echo "$ALBS" | wc -l | tr -d ' ')
    echo "$ALBS" | while read alb_name alb_type create_time; do
        echo "  $alb_name ($alb_type)"
    done
    echo ""
    ALB_COST=$(echo "$ALB_COUNT * 0.50" | bc)
    print_warning "Load Balancers are NOT Free Tier (~\$${ALB_COST}/day)"
fi

echo ""

# Free Tier usage warning
print_info "🎁 Free Tier Limits:"
echo ""
echo "  EC2: 750 hours/month of t2.micro (enough for 1 instance running 24/7)"
echo "  RDS: 750 hours/month of db.t3.micro (enough for 1 instance running 24/7)"
echo "  EBS: 30 GB of General Purpose SSD"
echo "  Data Transfer: 15 GB out per month"
echo ""
print_info "💡 To check detailed Free Tier usage:"
echo "   AWS Console → Billing → Free Tier"
echo ""

# Recommendations
print_header "Recommendations"

if (( $(echo "$TOTAL_COST > 1" | bc -l) )); then
    echo "✓ Review costs daily for the first week"
    echo "✓ Stop or terminate unused resources immediately"
    echo "✓ Remember: ALB costs money even with no traffic"
    echo "✓ If done for the day, run: ./cleanup-day1.sh"
else
    echo -e "${GREEN}✓ Costs look good!${NC}"
    echo "✓ Keep monitoring daily"
    echo "✓ Clean up when finished: ./cleanup-day1.sh"
fi

echo ""
print_info "Last updated: $(date)"
echo ""

###############################################################################
# End of Script
###############################################################################
