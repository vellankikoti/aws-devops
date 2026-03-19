# Day 6: Observability Quick Reference

## PromQL Queries

| Query | Description |
|-------|-------------|
| `up` | Check if targets are up |
| `rate(http_requests_total[5m])` | Request rate |
| `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))` | P99 latency |
| `sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)` | CPU by pod |
| `container_memory_usage_bytes / container_spec_memory_limit_bytes` | Memory % |
| `kube_pod_container_status_restarts_total` | Container restarts |

## Access Services

```bash
kubectl port-forward svc/prometheus -n monitoring 9090:9090
kubectl port-forward svc/grafana -n monitoring 3000:3000
kubectl port-forward svc/alertmanager -n monitoring 9093:9093
```

## Grafana

- Default login: admin / admin
- Add datasource: Configuration → Data Sources → Prometheus
- Import dashboard: + → Import → paste JSON or ID

## AlertManager

```bash
# Silence an alert
amtool silence add alertname=HighCPUUsage --duration=2h

# View active alerts
amtool alert

# Check config
amtool check-config alertmanager.yml
```
