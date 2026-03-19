#!/bin/bash
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS=0; FAIL=0

check() {
  if command -v "$1" &>/dev/null; then
    echo -e "  ${GREEN}✅${NC} $1 $(eval "$2" 2>/dev/null | head -1)"; ((PASS++))
  else
    echo -e "  ${RED}❌${NC} $1 not found - $3"; ((FAIL++))
  fi
}

echo -e "${YELLOW}=== Prerequisites Check ===${NC}"
echo ""

echo "Required Tools:"
check "aws" "aws --version" "Install: https://aws.amazon.com/cli/"
check "git" "git --version" "Install: sudo yum install git"
check "ssh" "ssh -V 2>&1" "Install: sudo yum install openssh-clients"

echo ""
echo "Day-Specific Tools:"
check "terraform" "terraform --version" "Install on Day 2"
check "ansible" "ansible --version" "Install on Day 3"
check "docker" "docker --version" "Install on Day 1"
check "kubectl" "kubectl version --client --short 2>/dev/null" "Install on Day 5"

echo ""
echo "System Requirements:"
MEM=$(free -m 2>/dev/null | awk '/Mem:/{print $2}')
[ "${MEM:-0}" -ge 8000 ] && echo -e "  ${GREEN}✅${NC} RAM: ${MEM}MB" && ((PASS++)) || echo -e "  ${YELLOW}⚠${NC} RAM: ${MEM:-unknown}MB (8GB+ recommended)" && ((FAIL++))

DISK=$(df -BG / 2>/dev/null | awk 'NR==2{print $4}' | tr -d 'G')
[ "${DISK:-0}" -ge 20 ] && echo -e "  ${GREEN}✅${NC} Disk: ${DISK}GB free" && ((PASS++)) || echo -e "  ${YELLOW}⚠${NC} Disk: ${DISK:-unknown}GB (20GB+ recommended)"

echo ""
echo "AWS Credentials:"
if aws sts get-caller-identity &>/dev/null; then
  ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
  echo -e "  ${GREEN}✅${NC} AWS configured (Account: $ACCOUNT)"; ((PASS++))
else
  echo -e "  ${RED}❌${NC} AWS not configured. Run: aws configure"; ((FAIL++))
fi

echo ""
echo -e "Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
