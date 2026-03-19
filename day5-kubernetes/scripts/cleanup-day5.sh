#!/bin/bash
set -e
echo "Day 5 Cleanup"
echo ""

read -p "Delete EKS cluster? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
  echo "Deleting namespace..."
  kubectl delete namespace sock-shop 2>/dev/null || true
  echo "Deleting EKS cluster..."
  eksctl delete cluster --name sockshop-cluster --region us-east-1
fi

read -p "Delete ECS cluster? (yes/no): " confirm_ecs
if [ "$confirm_ecs" = "yes" ]; then
  aws ecs delete-cluster --cluster sockshop-cluster --region us-east-1 2>/dev/null || true
fi

echo "Day 5 cleanup complete!"
