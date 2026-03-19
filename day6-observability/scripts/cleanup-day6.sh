#!/bin/bash
echo "Day 6 Cleanup: Removing monitoring stack..."
kubectl delete namespace monitoring 2>/dev/null || true
echo "Day 6 cleanup complete."
