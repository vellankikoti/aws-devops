#!/bin/bash
set -e
echo "Creating EKS Cluster (this takes ~15 minutes)..."
echo "WARNING: EKS control plane costs $0.10/hour ($2.40/day)"
read -p "Continue? (yes/no): " confirm
[ "$confirm" != "yes" ] && exit 0

eksctl create cluster \
  --name sockshop-cluster \
  --region us-east-1 \
  --nodegroup-name sockshop-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed \
  --tags "Project=SockShop,Environment=dev"

echo "EKS Cluster created!"
kubectl get nodes
