#!/bin/bash
set -e
echo "=== Sock Shop Backup Strategy ==="

# RDS Snapshot
echo "Creating RDS snapshot..."
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
aws rds create-db-snapshot \
  --db-instance-identifier sockshop-db \
  --db-snapshot-identifier "sockshop-backup-${TIMESTAMP}"

# S3 backup of configs
echo "Backing up configurations to S3..."
BACKUP_BUCKET="sockshop-backups-$(aws sts get-caller-identity --query Account --output text)"
aws s3 sync /opt/sockshop/ "s3://${BACKUP_BUCKET}/app-config/${TIMESTAMP}/" --exclude "*.log"

echo "Backup complete! Snapshot: sockshop-backup-${TIMESTAMP}"
