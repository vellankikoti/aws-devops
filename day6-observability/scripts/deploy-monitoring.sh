#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="${SCRIPT_DIR}/.."

echo "Deploying Observability Stack..."

kubectl create namespace monitoring 2>/dev/null || true

echo "1/4 Deploying Prometheus..."
kubectl apply -f "${BASE}/prometheus/k8s-deployment.yaml"

echo "2/4 Deploying Grafana..."
kubectl apply -f "${BASE}/grafana/provisioning/"
kubectl apply -f "${BASE}/grafana/grafana-deployment.yaml"

echo "3/4 Deploying AlertManager..."
kubectl apply -f "${BASE}/alertmanager/k8s-deployment.yaml"

echo "4/4 Deploying OpenTelemetry Collector..."
kubectl apply -f "${BASE}/opentelemetry/k8s-deployment.yaml"

echo ""
echo "Monitoring stack deployed!"
echo "  Prometheus: kubectl port-forward svc/prometheus -n monitoring 9090:9090"
echo "  Grafana:    kubectl port-forward svc/grafana -n monitoring 3000:3000"
echo "  AlertMgr:   kubectl port-forward svc/alertmanager -n monitoring 9093:9093"
