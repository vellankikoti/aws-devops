#!/bin/bash
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
PASS=0; FAIL=0
check() { if [ $? -eq 0 ] && [ -n "$2" ]; then echo -e "  ${GREEN}✅${NC} $1"; ((PASS++)); else echo -e "  ${RED}❌${NC} $1"; ((FAIL++)); fi; }

echo "Day 6: Observability Verification"
r=$(kubectl get pods -n monitoring -l app=prometheus 2>/dev/null | grep Running); check "Prometheus running" "$r"
r=$(kubectl get pods -n monitoring -l app=grafana 2>/dev/null | grep Running); check "Grafana running" "$r"
r=$(kubectl get pods -n monitoring -l app=alertmanager 2>/dev/null | grep Running); check "AlertManager running" "$r"
r=$(kubectl get pods -n monitoring -l app=otel-collector 2>/dev/null | grep Running); check "OTel Collector running" "$r"
echo -e "\nResults: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
