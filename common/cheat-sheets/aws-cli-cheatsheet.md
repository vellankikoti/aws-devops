# AWS CLI Cheat Sheet

## IAM
```bash
aws iam list-users
aws iam create-user --user-name NAME
aws iam list-attached-user-policies --user-name NAME
aws sts get-caller-identity
```

## EC2
```bash
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"
aws ec2 start-instances --instance-ids i-xxx
aws ec2 stop-instances --instance-ids i-xxx
aws ec2 terminate-instances --instance-ids i-xxx
aws ec2 describe-security-groups
aws ec2 describe-vpcs
aws ec2 describe-subnets
```

## RDS
```bash
aws rds describe-db-instances
aws rds create-db-snapshot --db-instance-identifier ID --db-snapshot-identifier NAME
aws rds describe-db-snapshots
```

## S3
```bash
aws s3 ls
aws s3 cp file.txt s3://bucket/
aws s3 sync ./dir s3://bucket/dir
aws s3 rm s3://bucket/file.txt
```

## EKS
```bash
aws eks list-clusters
aws eks describe-cluster --name NAME
aws eks update-kubeconfig --name NAME
```

## CloudWatch
```bash
aws cloudwatch list-metrics --namespace AWS/EC2
aws logs describe-log-groups
aws logs get-log-events --log-group-name NAME --log-stream-name STREAM
```

## Cost
```bash
aws ce get-cost-and-usage --time-period Start=YYYY-MM-DD,End=YYYY-MM-DD --granularity DAILY --metrics UnblendedCost
```
