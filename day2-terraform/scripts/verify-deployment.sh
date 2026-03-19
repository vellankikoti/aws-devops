#!/bin/bash
# =============================================================================
# Day 2 Verification Script
# =============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
PROJECT="sockshop"

check() {
  local desc="$1"
  local result="$2"
  if [ $? -eq 0 ] && [ -n "$result" ]; then
    echo -e "  ${GREEN}✅ PASS${NC}: $desc"
    ((PASS++))
  else
    echo -e "  ${RED}❌ FAIL${NC}: $desc"
    ((FAIL++))
  fi
}

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Day 2: Terraform Verification${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Check Terraform
echo "Checking Terraform installation..."
result=$(terraform --version 2>/dev/null)
check "Terraform installed" "$result"

# Check VPC
echo "Checking VPC..."
result=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=${PROJECT}" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
check "VPC exists (${result})" "$result"

# Check Subnets
echo "Checking Subnets..."
result=$(aws ec2 describe-subnets --filters "Name=tag:Project,Values=${PROJECT}" --query 'Subnets[*].SubnetId' --output text 2>/dev/null)
check "Subnets exist" "$result"

# Check EC2
echo "Checking EC2..."
result=$(aws ec2 describe-instances --filters "Name=tag:Project,Values=${PROJECT}" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null)
check "EC2 instance running (${result})" "$result"

# Check RDS
echo "Checking RDS..."
result=$(aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier,'${PROJECT}')].DBInstanceStatus" --output text 2>/dev/null)
check "RDS instance (${result})" "$result"

# Check ALB
echo "Checking ALB..."
result=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName,'${PROJECT}')].DNSName" --output text 2>/dev/null)
check "ALB exists (${result})" "$result"

# Check Security Groups
echo "Checking Security Groups..."
result=$(aws ec2 describe-security-groups --filters "Name=tag:Project,Values=${PROJECT}" --query 'SecurityGroups[*].GroupId' --output text 2>/dev/null)
check "Security groups exist" "$result"

echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "  Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo -e "${YELLOW}========================================${NC}"

if [ $FAIL -gt 0 ]; then
  exit 1
fi
