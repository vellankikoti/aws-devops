# Day 5: Kubernetes Quick Reference

## kubectl Essentials

| Command | Description |
|---------|-------------|
| `kubectl get pods -n sock-shop` | List pods |
| `kubectl get all -n sock-shop` | List all resources |
| `kubectl describe pod <name> -n sock-shop` | Pod details |
| `kubectl logs <pod> -n sock-shop` | Pod logs |
| `kubectl logs <pod> -n sock-shop -f` | Follow logs |
| `kubectl exec -it <pod> -n sock-shop -- /bin/sh` | Shell into pod |
| `kubectl scale deploy front-end --replicas=3 -n sock-shop` | Scale |
| `kubectl rollout status deploy/front-end -n sock-shop` | Rollout status |
| `kubectl rollout undo deploy/front-end -n sock-shop` | Rollback |
| `kubectl top pods -n sock-shop` | Resource usage |

## Debugging

```bash
# Why is pod not starting?
kubectl describe pod <pod-name> -n sock-shop

# Check events
kubectl get events -n sock-shop --sort-by='.lastTimestamp'

# Port forward for local testing
kubectl port-forward svc/front-end 8080:80 -n sock-shop
```

## EKS Commands

```bash
eksctl get cluster
eksctl get nodegroup --cluster sockshop-cluster
aws eks update-kubeconfig --name sockshop-cluster
```
