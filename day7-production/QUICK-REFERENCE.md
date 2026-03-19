# Day 7: Production Quick Reference

## Security Commands
```bash
aws iam list-users                              # List IAM users
aws iam list-mfa-devices --user-name USER       # Check MFA
aws ec2 describe-security-groups                 # List SGs
aws s3api get-bucket-acl --bucket BUCKET        # Check S3 ACL
aws kms list-keys                                # List KMS keys
```

## Cost Commands
```bash
aws ce get-cost-and-usage --time-period Start=YYYY-MM-DD,End=YYYY-MM-DD --granularity DAILY --metrics UnblendedCost
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"
aws rds describe-db-instances
```

## DR Commands
```bash
aws rds create-db-snapshot --db-instance-identifier ID --db-snapshot-identifier NAME
aws rds restore-db-instance-from-db-snapshot --db-instance-identifier NEW --db-snapshot-identifier SNAP
aws s3 sync s3://bucket/backup/ /local/restore/
```

## Well-Architected Pillars
1. **Operational Excellence** - Automate everything
2. **Security** - Least privilege, encrypt, audit
3. **Reliability** - Multi-AZ, auto-scaling, backups
4. **Performance** - Right-size, cache, CDN
5. **Cost Optimization** - Tag, monitor, right-size
6. **Sustainability** - Efficient resource usage
