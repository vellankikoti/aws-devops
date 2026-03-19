# Lab 04: Kubernetes Troubleshooting

## Scenario
Sock Shop pods are failing. Diagnose and fix each issue.

## Problem 1: Pod in Pending state
```bash
kubectl get pods -n sock-shop
# front-end-xxx   0/1   Pending   0   5m
```
**Hint:** Check `kubectl describe pod` for events. Common causes: resource limits, node selector.

## Problem 2: CrashLoopBackOff
```bash
# carts-xxx   0/1   CrashLoopBackOff   5   10m
```
**Hint:** Check `kubectl logs --previous`. Common causes: missing env vars, wrong image tag.

## Problem 3: Service not reachable
```bash
# curl http://front-end.sock-shop:80 → connection refused
```
**Hint:** Check service selector matches pod labels. Check endpoints.

## Debugging Commands
```bash
kubectl describe pod POD -n sock-shop
kubectl logs POD -n sock-shop --previous
kubectl get events -n sock-shop --sort-by='.lastTimestamp'
kubectl get endpoints -n sock-shop
```
