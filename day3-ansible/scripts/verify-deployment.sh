#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
PASS=0; FAIL=0

check() {
  if [ $? -eq 0 ] && [ -n "$2" ]; then
    echo -e "  ${GREEN}✅ PASS${NC}: $1"; ((PASS++))
  else
    echo -e "  ${RED}❌ FAIL${NC}: $1"; ((FAIL++))
  fi
}

echo -e "${YELLOW}Day 3: Ansible Verification${NC}"
echo ""

echo "Checking Ansible..."
result=$(ansible --version 2>/dev/null | head -1)
check "Ansible installed ($result)" "$result"

echo "Checking connectivity..."
result=$(ansible all -m ping 2>/dev/null | grep SUCCESS)
check "Ansible can reach hosts" "$result"

echo "Checking Docker on remote..."
result=$(ansible webservers -m shell -a "docker --version" 2>/dev/null | grep "Docker version")
check "Docker installed on remotes" "$result"

echo "Checking Sock Shop..."
result=$(ansible webservers -m shell -a "docker-compose -f /opt/sockshop/docker-compose.yml ps" 2>/dev/null | grep "Up")
check "Sock Shop containers running" "$result"

echo ""
echo -e "Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
