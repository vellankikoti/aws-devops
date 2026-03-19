#!/bin/bash
# =============================================================================
# Setup Terraform Remote Backend (S3 + DynamoDB)
# =============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
BUCKET_NAME="sockshop-terraform-state-${ACCOUNT_ID}"
TABLE_NAME="terraform-state-lock"
REGION="us-east-1"

echo -e "${GREEN}Setting up Terraform Remote Backend${NC}"
echo "Account ID: ${ACCOUNT_ID}"
echo "Bucket: ${BUCKET_NAME}"
echo "DynamoDB Table: ${TABLE_NAME}"
echo ""

# Create S3 bucket
echo -e "${YELLOW}Creating S3 bucket...${NC}"
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo -e "${GREEN}Bucket already exists${NC}"
else
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}"

  aws s3api put-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled

  aws s3api put-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration '{
      "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
    }'

  aws s3api put-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

  echo -e "${GREEN}S3 bucket created with versioning and encryption${NC}"
fi

# Create DynamoDB table
echo -e "${YELLOW}Creating DynamoDB table...${NC}"
if aws dynamodb describe-table --table-name "${TABLE_NAME}" --region "${REGION}" >/dev/null 2>&1; then
  echo -e "${GREEN}DynamoDB table already exists${NC}"
else
  aws dynamodb create-table \
    --table-name "${TABLE_NAME}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"

  echo -e "${GREEN}DynamoDB table created${NC}"
fi

echo ""
echo -e "${GREEN}Backend setup complete!${NC}"
echo ""
echo "Update your backend.tf with:"
echo ""
echo "terraform {"
echo "  backend \"s3\" {"
echo "    bucket         = \"${BUCKET_NAME}\""
echo "    key            = \"dev/terraform.tfstate\""
echo "    region         = \"${REGION}\""
echo "    dynamodb_table = \"${TABLE_NAME}\""
echo "    encrypt        = true"
echo "  }"
echo "}"
echo ""
echo "Then run: terraform init -migrate-state"
