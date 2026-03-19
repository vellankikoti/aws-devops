#!/bin/bash
set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Day 3: Ansible Cleanup${NC}"
echo "This script cleans up Ansible artifacts and optionally stops services."
echo ""

# Clean local files
echo -e "${YELLOW}Cleaning local Ansible artifacts...${NC}"
find "$(dirname "$0")/.." -name "*.retry" -delete 2>/dev/null || true
rm -f "$(dirname "$0")/../ansible.log" 2>/dev/null || true

echo -e "${GREEN}Local cleanup complete.${NC}"
echo ""
echo "Note: To clean up AWS resources (EC2, etc.), use Day 2's Terraform destroy."
echo "  cd ../day2-terraform/environments/dev && terraform destroy"
