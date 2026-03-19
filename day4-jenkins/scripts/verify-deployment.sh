#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
PASS=0; FAIL=0

check() {
  if [ $? -eq 0 ] && [ -n "$2" ]; then
    echo -e "  ${GREEN}✅${NC} $1"; ((PASS++))
  else
    echo -e "  ${RED}❌${NC} $1"; ((FAIL++))
  fi
}

echo "Day 4: Jenkins Verification"
echo ""

result=$(java -version 2>&1 | head -1)
check "Java installed ($result)" "$result"

result=$(systemctl is-active jenkins 2>/dev/null)
check "Jenkins service running ($result)" "$result"

result=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/login 2>/dev/null)
check "Jenkins UI accessible (HTTP $result)" "$result"

echo ""
echo -e "Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
