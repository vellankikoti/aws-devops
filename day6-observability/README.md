# Day 6: Observability Stack (Prometheus, Grafana, OpenTelemetry)

**Theme: "See Everything, Know Everything"**

**Time:** 7-8 hours | **Cost:** ~$3.50/day (same as Day 5) | **Level:** Advanced

---

## My Take: The Night I Learned Why Observability Matters

2 AM. Phone rings. "The checkout service is down." I SSH into the server. CPU looks fine. Memory looks fine. Disk looks fine. But orders aren't processing. I spent 3 hours debugging blind because we had no observability.

Turns out, the payment service was timing out because a downstream dependency had increased its latency from 50ms to 5000ms. If we'd had proper metrics and tracing, I would have seen this in 30 seconds instead of 3 hours.

That night changed everything. At TransUnion, we now have the three pillars of observability:
- **Metrics** (Prometheus) - What's happening NOW
- **Logs** (CloudWatch/Loki) - What happened in the PAST
- **Traces** (OpenTelemetry) - WHY it happened

Today, you'll build all three.

---

## What You'll Build Today

```
┌─────────────────────────────────────────────────────────┐
│                   Observability Stack                    │
│                                                         │
│  ┌───────────┐  ┌───────────┐  ┌───────────────────┐   │
│  │Prometheus │  │  Grafana  │  │   AlertManager    │   │
│  │ (Metrics) │→│(Dashboards)│  │   (Alerts)        │   │
│  └─────┬─────┘  └───────────┘  └───────────────────┘   │
│        │                                                │
│  ┌─────▼──────────────────────────────────────────┐     │
│  │              Sock Shop Services                 │     │
│  │  front-end │ catalogue │ carts │ orders │ ...  │     │
│  └────────────────────────────────────────────────┘     │
│        │                                                │
│  ┌─────▼─────┐  ┌──────────────────┐                    │
│  │   OTel    │  │   Node Exporter  │                    │
│  │ Collector │  │  (Host Metrics)  │                    │
│  └───────────┘  └──────────────────┘                    │
└─────────────────────────────────────────────────────────┘
```

---

## Morning Session: Prometheus Setup (2 hours)

### Step 1: Deploy Prometheus

```bash
# Deploy the entire monitoring stack
chmod +x scripts/deploy-monitoring.sh
./scripts/deploy-monitoring.sh
```

Or manually:
```bash
kubectl create namespace monitoring
kubectl apply -f prometheus/k8s-deployment.yaml
kubectl apply -f prometheus/rules/
```

### Step 2: Understand Prometheus

Prometheus scrapes metrics from your services at regular intervals. It stores them as time series data.

**Key concepts:**
- **Scrape targets** - Services Prometheus collects from
- **PromQL** - Query language for metrics
- **Recording rules** - Pre-computed queries
- **Alert rules** - Conditions that trigger alerts

### Step 3: Access Prometheus UI

```bash
kubectl port-forward svc/prometheus -n monitoring 9090:9090
# Open http://localhost:9090
```

**Try these PromQL queries:**
```promql
# CPU usage per pod
rate(container_cpu_usage_seconds_total{namespace="sock-shop"}[5m])

# Memory usage
container_memory_usage_bytes{namespace="sock-shop"}

# HTTP request rate
rate(http_requests_total{namespace="sock-shop"}[5m])

# 99th percentile latency
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

---

## Afternoon Session: Grafana & Dashboards (3 hours)

### Step 1: Deploy Grafana

```bash
kubectl apply -f grafana/grafana-deployment.yaml
kubectl port-forward svc/grafana -n monitoring 3000:3000
# Login: admin / admin (change immediately!)
```

### Step 2: Add Prometheus Data Source

Grafana auto-provisions Prometheus via `grafana/provisioning/datasources.yaml`.

### Step 3: Import Dashboards

We provide three pre-built dashboards:
1. **Node Metrics** - CPU, Memory, Disk, Network per node
2. **Sock Shop Overview** - Application-level metrics
3. **Kubernetes Cluster** - Cluster-wide health

> **Interactive Exercise:** After importing dashboards, try creating your own panel. Pick a PromQL query and visualize it!

---

## Evening Session: OpenTelemetry & Alerting (2 hours)

### OpenTelemetry Collector

```bash
kubectl apply -f opentelemetry/k8s-deployment.yaml
```

The OTel Collector receives traces from services, processes them, and exports to backends.

### AlertManager

```bash
kubectl apply -f alertmanager/k8s-deployment.yaml
```

Alert rules fire when conditions are met (e.g., pod restarts > 5 in 10 minutes).

---

## Interactive Exercises

### Challenge 1: Build Your Own Dashboard
Create a Grafana dashboard showing Sock Shop request rate, error rate, and latency.

### Challenge 2: Create a Custom Alert
Write a Prometheus alert that fires when any pod restarts more than 3 times in 5 minutes.

### Challenge 3: Generate Load and Watch
```bash
# Generate load
chmod +x scripts/generate-load.sh
./scripts/generate-load.sh

# Watch dashboards update in real-time!
```

---

## Common Mistakes I Made

1. **Too many alerts** = alert fatigue. Only alert on actionable items.
2. **Too many dashboards** that nobody looks at. Start with 3 essential ones.
3. **Not setting retention** - Prometheus fills disk if unbounded.
4. **Missing labels** - Always label metrics for filtering.
5. **Alerting on symptoms, not causes** - Alert on "5xx errors", not "CPU high".

---

## Deeper Learning Resources

- [Prometheus](https://github.com/prometheus/prometheus) - Official repo
- [Grafana](https://github.com/grafana/grafana) - Official repo
- [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector) - OTel
- [Prometheus Community Helm Charts](https://github.com/prometheus-community/helm-charts) - Easy install
- [Awesome Prometheus Alerts](https://github.com/samber/awesome-prometheus-alerts) - Alert rules collection

---

## Cleanup

```bash
chmod +x scripts/cleanup-day6.sh
./scripts/cleanup-day6.sh
```

-Koti
