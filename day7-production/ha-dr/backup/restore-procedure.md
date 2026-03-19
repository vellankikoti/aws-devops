# Restore Procedure

## RDS Database Restore

1. **Find latest snapshot:**
   ```bash
   aws rds describe-db-snapshots --db-instance-identifier sockshop-db \
     --query 'DBSnapshots[-1].DBSnapshotIdentifier' --output text
   ```

2. **Restore from snapshot:**
   ```bash
   aws rds restore-db-instance-from-db-snapshot \
     --db-instance-identifier sockshop-db-restored \
     --db-snapshot-identifier <snapshot-id>
   ```

3. **Update application config to point to new DB**

4. **Verify data integrity**

## Application Config Restore

```bash
aws s3 sync s3://sockshop-backups-ACCOUNT/app-config/TIMESTAMP/ /opt/sockshop/
docker-compose -f /opt/sockshop/docker-compose.yml up -d
```

## Estimated Recovery Times
- RDS restore: ~15 minutes
- App config restore: ~5 minutes
- Health check verification: ~5 minutes
- **Total RTO: ~30 minutes**
