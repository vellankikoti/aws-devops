# kubectl Cheat Sheet

## Basics
```bash
kubectl get pods/svc/deploy/nodes -n NAMESPACE
kubectl describe pod POD -n NS
kubectl logs POD -n NS [-f] [--previous]
kubectl exec -it POD -n NS -- /bin/sh
kubectl apply -f file.yaml
kubectl delete -f file.yaml
```

## Debugging
```bash
kubectl get events --sort-by='.lastTimestamp' -n NS
kubectl top pods -n NS
kubectl get endpoints -n NS
kubectl port-forward svc/NAME PORT:PORT -n NS
```

## Scaling
```bash
kubectl scale deploy NAME --replicas=N -n NS
kubectl autoscale deploy NAME --min=2 --max=10 --cpu-percent=70 -n NS
```

## Rollouts
```bash
kubectl rollout status deploy/NAME -n NS
kubectl rollout history deploy/NAME -n NS
kubectl rollout undo deploy/NAME -n NS
```
