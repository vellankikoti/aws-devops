#!/bin/bash
set -e
echo "!!! EMERGENCY CLEANUP !!!"
echo "This aggressively deletes ALL resources tagged Project=SockShop"
read -p "Type 'EMERGENCY' to confirm: " confirm
[ "$confirm" != "EMERGENCY" ] && exit 0

REGION="us-east-1"

echo "Terminating EC2 instances..."
INSTANCES=$(aws ec2 describe-instances --filters "Name=tag:Project,Values=SockShop" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text --region $REGION 2>/dev/null)
[ -n "$INSTANCES" ] && aws ec2 terminate-instances --instance-ids $INSTANCES --region $REGION

echo "Deleting load balancers..."
for arn in $(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerArn' --output text --region $REGION 2>/dev/null); do
  name=$(aws elbv2 describe-tags --resource-arns $arn --query "TagDescriptions[?Tags[?Key=='Project'&&Value=='SockShop']].ResourceArn" --output text --region $REGION 2>/dev/null)
  [ -n "$name" ] && aws elbv2 delete-load-balancer --load-balancer-arn $arn --region $REGION
done

echo "Deleting RDS instances..."
for db in $(aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier,'sockshop')].DBInstanceIdentifier" --output text --region $REGION 2>/dev/null); do
  aws rds delete-db-instance --db-instance-identifier $db --skip-final-snapshot --region $REGION 2>/dev/null || true
done

echo "Deleting EKS clusters..."
aws eks delete-cluster --name sockshop-cluster --region $REGION 2>/dev/null || true

echo "Emergency cleanup initiated! Resources may take a few minutes to fully terminate."
echo "Monitor in AWS Console."
