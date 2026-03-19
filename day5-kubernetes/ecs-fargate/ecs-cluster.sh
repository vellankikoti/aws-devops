#!/bin/bash
set -e
echo "Creating ECS Fargate Cluster for Sock Shop..."

CLUSTER_NAME="sockshop-cluster"
REGION="us-east-1"

# Create ECS cluster
aws ecs create-cluster --cluster-name $CLUSTER_NAME --region $REGION

# Create CloudWatch log group
aws logs create-log-group --log-group-name /ecs/sockshop --region $REGION 2>/dev/null || true

# Register task definitions
for td in task-definitions/*.json; do
  echo "Registering $(basename $td)..."
  aws ecs register-task-definition --cli-input-json file://$td --region $REGION
done

echo "ECS Cluster created! Create services with:"
echo "  aws ecs create-service --cluster $CLUSTER_NAME --service-name front-end ..."
