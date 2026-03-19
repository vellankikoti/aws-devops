# Security Compliance Checklist

## Identity & Access Management
- [ ] MFA enabled for all IAM users
- [ ] Root account has MFA and no access keys
- [ ] IAM policies follow least privilege
- [ ] No hardcoded credentials in code
- [ ] Secrets stored in AWS Secrets Manager

## Network Security
- [ ] VPC with public and private subnets
- [ ] Security groups follow least privilege
- [ ] No 0.0.0.0/0 on SSH (port 22)
- [ ] NACLs configured as additional layer
- [ ] VPC Flow Logs enabled

## Data Protection
- [ ] EBS volumes encrypted
- [ ] S3 buckets not publicly accessible
- [ ] S3 bucket versioning enabled
- [ ] RDS encryption at rest enabled
- [ ] TLS/HTTPS for all external communication

## Monitoring & Logging
- [ ] CloudTrail enabled (all regions)
- [ ] CloudWatch alarms for critical metrics
- [ ] VPC Flow Logs enabled
- [ ] Access logging for S3 buckets
- [ ] Centralized log management

## Incident Response
- [ ] DR runbook documented and tested
- [ ] Backup strategy implemented
- [ ] Restore procedure tested
- [ ] Escalation contacts defined
- [ ] Post-mortem process established
