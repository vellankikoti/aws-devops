#!/bin/bash
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
PASS=0; FAIL=0

check() { if [ $? -eq 0 ] && [ -n "$2" ]; then echo -e "  ${GREEN}✅${NC} $1"; ((PASS++)); else echo -e "  ${RED}❌${NC} $1"; ((FAIL++)); fi; }

echo "Day 5: Kubernetes Verification"
echo ""

result=$(kubectl cluster-info 2>/dev/null | head -1)
check "Cluster reachable" "$result"

result=$(kubectl get nodes 2>/dev/null | grep Ready)
check "Nodes ready" "$result"

result=$(kubectl get pods -n sock-shop 2>/dev/null | grep Running)
check "Pods running" "$result"

result=$(kubectl get svc front-end -n sock-shop 2>/dev/null)
check "Front-end service exists" "$result"

result=$(kubectl get hpa -n sock-shop 2>/dev/null | grep front-end)
check "HPA configured" "$result"

echo ""
echo -e "Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
