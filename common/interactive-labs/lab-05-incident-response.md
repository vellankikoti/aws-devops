# Lab 05: Simulated Production Incident

## Scenario
It's 2:47 AM. You receive an alert: "Sock Shop - High Error Rate (>10%)"

## Phase 1: Triage (5 minutes)
1. Check which services are affected
2. Check error rates per service
3. Check if it's customer-impacting

```bash
# Check pod status
kubectl get pods -n sock-shop
# Check recent events
kubectl get events -n sock-shop --sort-by='.lastTimestamp' | head -20
# Check error rate in Prometheus
# sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
```

## Phase 2: Diagnose (10 minutes)
1. Identify the root cause service
2. Check logs for error details
3. Check if a recent deployment caused it

## Phase 3: Mitigate (10 minutes)
1. Rollback if deployment-related
2. Scale up if capacity-related
3. Restart if transient

## Phase 4: Post-Mortem
Write a post-mortem with:
- Timeline of events
- Root cause
- Impact
- What went well
- What could be improved
- Action items
