#!/bin/bash
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${YELLOW}=== AWS Cost Analysis ===${NC}"
echo ""

echo "Month-to-Date Costs:"
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --query 'ResultsByTime[0].Total.UnblendedCost' 2>/dev/null || echo "  (Cost Explorer not available - enable in AWS Console)"

echo ""
echo "Running Resources (potential costs):"
echo "  EC2 instances: $(aws ec2 describe-instances --filters 'Name=instance-state-name,Values=running' --query 'Reservations[*].Instances[*].InstanceId' --output text 2>/dev/null | wc -w)"
echo "  RDS instances: $(aws rds describe-db-instances --query 'DBInstances[*].DBInstanceIdentifier' --output text 2>/dev/null | wc -w)"
echo "  Load Balancers: $(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerArn' --output text 2>/dev/null | wc -w)"
echo "  EKS Clusters: $(aws eks list-clusters --query 'clusters' --output text 2>/dev/null | wc -w)"

echo ""
echo -e "${YELLOW}Optimization Recommendations:${NC}"
echo "  1. Stop EC2 instances when not in use"
echo "  2. Delete unused EBS volumes"
echo "  3. Use t3.micro instead of t2.micro (cheaper)"
echo "  4. Delete EKS cluster when not needed (\$2.40/day)"
echo "  5. Set up AWS Budget alerts"
