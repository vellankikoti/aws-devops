#!/bin/bash
set -e
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
ISSUES=0

echo -e "${YELLOW}=== AWS Security Audit ===${NC}"
echo ""

echo "Checking IAM..."
users_no_mfa=$(aws iam list-users --query 'Users[?PasswordLastUsed!=`null`].UserName' --output text 2>/dev/null)
for user in $users_no_mfa; do
  mfa=$(aws iam list-mfa-devices --user-name "$user" --query 'MFADevices' --output text 2>/dev/null)
  if [ -z "$mfa" ]; then
    echo -e "  ${RED}✗ User '$user' has no MFA${NC}"; ((ISSUES++))
  fi
done

echo "Checking Security Groups..."
open_sgs=$(aws ec2 describe-security-groups --filters "Name=ip-permission.cidr,Values=0.0.0.0/0" --query 'SecurityGroups[*].[GroupId,GroupName]' --output text 2>/dev/null)
if [ -n "$open_sgs" ]; then
  echo -e "  ${YELLOW}⚠ Security groups open to 0.0.0.0/0:${NC}"
  echo "$open_sgs" | while read line; do echo "    $line"; done
  ((ISSUES++))
fi

echo "Checking Public S3 Buckets..."
for bucket in $(aws s3api list-buckets --query 'Buckets[*].Name' --output text 2>/dev/null); do
  acl=$(aws s3api get-bucket-acl --bucket "$bucket" 2>/dev/null | grep -c "AllUsers" || true)
  if [ "$acl" -gt 0 ]; then
    echo -e "  ${RED}✗ Bucket '$bucket' is publicly accessible${NC}"; ((ISSUES++))
  fi
done

echo "Checking EBS Encryption..."
unencrypted=$(aws ec2 describe-volumes --filters "Name=encrypted,Values=false" --query 'Volumes[*].VolumeId' --output text 2>/dev/null)
if [ -n "$unencrypted" ]; then
  echo -e "  ${YELLOW}⚠ Unencrypted EBS volumes: $unencrypted${NC}"; ((ISSUES++))
fi

echo ""
if [ $ISSUES -eq 0 ]; then
  echo -e "${GREEN}No security issues found!${NC}"
else
  echo -e "${RED}Found $ISSUES security issue(s). Please remediate.${NC}"
fi
