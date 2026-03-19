#!/bin/bash
echo "=== Chaos Engineering Experiments ==="
echo "WARNING: Only run in non-production environments!"
echo ""

PS3="Select experiment: "
options=("Kill random pod" "Simulate high CPU" "Block network" "Cancel")
select opt in "${options[@]}"; do
  case $opt in
    "Kill random pod")
      POD=$(kubectl get pods -n sock-shop -o jsonpath='{.items[0].metadata.name}')
      echo "Killing pod: $POD"
      kubectl delete pod "$POD" -n sock-shop
      echo "Watch recovery: kubectl get pods -n sock-shop -w"
      break ;;
    "Simulate high CPU")
      echo "Creating CPU stress pod..."
      kubectl run stress --image=progrium/stress -- --cpu 2 --timeout 60s
      echo "Stress pod running for 60s. Watch HPA: kubectl get hpa -n sock-shop -w"
      break ;;
    "Block network")
      echo "This requires network policy support."
      echo "Apply: kubectl apply -f network-policy-deny-all.yaml"
      break ;;
    "Cancel") break ;;
  esac
done
