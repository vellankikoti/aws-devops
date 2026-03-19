#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${RED}=== MASTER CLEANUP: ALL 7 DAYS ===${NC}"
echo "This will delete ALL resources created during the course."
echo ""
read -p "Type 'DELETE ALL' to confirm: " confirm
[ "$confirm" != "DELETE ALL" ] && echo "Cancelled." && exit 0

echo -e "${YELLOW}Cleaning Day 6: Monitoring...${NC}"
kubectl delete namespace monitoring 2>/dev/null || true

echo -e "${YELLOW}Cleaning Day 5: Kubernetes...${NC}"
kubectl delete namespace sock-shop 2>/dev/null || true
eksctl delete cluster --name sockshop-cluster --region us-east-1 2>/dev/null || true
aws ecs delete-cluster --cluster sockshop-cluster 2>/dev/null || true

echo -e "${YELLOW}Cleaning Day 4: Jenkins...${NC}"
# Jenkins is on EC2, will be deleted with Terraform

echo -e "${YELLOW}Cleaning Day 2: Terraform resources...${NC}"
cd "$(dirname "$0")/../../day2-terraform/environments/dev" 2>/dev/null && terraform destroy -auto-approve 2>/dev/null || true

echo -e "${YELLOW}Cleaning Terraform backend...${NC}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
aws s3 rm "s3://sockshop-terraform-state-${ACCOUNT_ID}" --recursive 2>/dev/null || true
aws s3api delete-bucket --bucket "sockshop-terraform-state-${ACCOUNT_ID}" 2>/dev/null || true
aws dynamodb delete-table --table-name terraform-state-lock 2>/dev/null || true

echo -e "${YELLOW}Cleaning tagged resources...${NC}"
# Delete any remaining resources tagged with Project=SockShop
for sg in $(aws ec2 describe-security-groups --filters "Name=tag:Project,Values=SockShop" --query 'SecurityGroups[*].GroupId' --output text 2>/dev/null); do
  aws ec2 delete-security-group --group-id "$sg" 2>/dev/null || true
done

echo ""
echo -e "${GREEN}=== Master cleanup complete! ===${NC}"
echo "Verify in AWS Console that no resources remain."
echo "Check AWS Cost Explorer in 24 hours to confirm no charges."
