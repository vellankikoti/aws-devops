#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFESTS="${SCRIPT_DIR}/../manifests"

echo "Deploying Sock Shop to Kubernetes..."

kubectl apply -f "${MANIFESTS}/namespace.yaml"
kubectl apply -f "${MANIFESTS}/secrets/"
kubectl apply -f "${MANIFESTS}/configmaps/"
kubectl apply -f "${MANIFESTS}/deployments/"
kubectl apply -f "${MANIFESTS}/services/"

echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=front-end -n sock-shop --timeout=300s

echo ""
echo "Sock Shop deployed! Check status:"
echo "  kubectl get pods -n sock-shop"
echo "  kubectl get svc -n sock-shop"

# Apply ingress
echo ""
echo "Applying ingress..."
kubectl apply -f "${MANIFESTS}/ingress.yaml"
kubectl get ingress -n sock-shop
