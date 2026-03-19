#!/bin/bash
# =============================================================================
# Day 2 Cleanup Script
# =============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Day 2: Terraform Cleanup${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEV_DIR="${SCRIPT_DIR}/../environments/dev"

echo -e "${YELLOW}This will destroy ALL Terraform-managed resources.${NC}"
read -p "Are you sure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Cleanup cancelled."
  exit 0
fi

# Destroy dev environment
if [ -d "$DEV_DIR" ] && [ -f "$DEV_DIR/.terraform/terraform.tfstate" ] || [ -d "$DEV_DIR/.terraform" ]; then
  echo -e "${YELLOW}Destroying dev environment...${NC}"
  cd "$DEV_DIR"
  terraform destroy -auto-approve 2>/dev/null || echo -e "${YELLOW}Dev environment already clean or not initialized${NC}"
else
  echo -e "${GREEN}Dev environment not initialized, skipping${NC}"
fi

# Clean up backend resources (optional)
read -p "Also delete S3 state bucket and DynamoDB lock table? (yes/no): " cleanup_backend
if [ "$cleanup_backend" = "yes" ]; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
  BUCKET="sockshop-terraform-state-${ACCOUNT_ID}"

  echo -e "${YELLOW}Emptying and deleting S3 bucket...${NC}"
  aws s3 rm "s3://${BUCKET}" --recursive 2>/dev/null || true
  aws s3api delete-bucket --bucket "${BUCKET}" 2>/dev/null || true

  echo -e "${YELLOW}Deleting DynamoDB table...${NC}"
  aws dynamodb delete-table --table-name terraform-state-lock 2>/dev/null || true
fi

# Clean local Terraform files
echo -e "${YELLOW}Cleaning local Terraform files...${NC}"
find "${SCRIPT_DIR}/.." -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
find "${SCRIPT_DIR}/.." -name "*.tfstate*" -type f -delete 2>/dev/null || true
find "${SCRIPT_DIR}/.." -name ".terraform.lock.hcl" -type f -delete 2>/dev/null || true

echo ""
echo -e "${GREEN}Day 2 cleanup complete!${NC}"
