# Disaster Recovery Runbook

## Recovery Objectives
- **RTO**: 30 minutes
- **RPO**: 1 hour (based on backup frequency)

## Severity Levels
| Level | Description | Response Time |
|-------|-------------|---------------|
| P1 | Complete outage | 15 minutes |
| P2 | Degraded service | 30 minutes |
| P3 | Minor issue | 2 hours |

## Failure Scenarios

### Scenario 1: Single EC2 Instance Failure
- **Detection**: CloudWatch alarm, ALB health check
- **Auto-recovery**: ASG launches replacement
- **Manual action**: None required
- **RTO**: 5 minutes

### Scenario 2: AZ Failure
- **Detection**: Multiple instance failures
- **Auto-recovery**: ASG launches in healthy AZ
- **Manual action**: Verify RDS failover
- **RTO**: 15 minutes

### Scenario 3: Database Corruption
- **Detection**: Application errors, health check failures
- **Recovery**: Restore from latest snapshot
- **Manual action**: Follow restore procedure
- **RTO**: 30 minutes

### Scenario 4: Region Failure
- **Detection**: All services unreachable
- **Recovery**: Deploy to backup region using Terraform
- **Manual action**: Update DNS, restore from S3 cross-region backup
- **RTO**: 2 hours

## Escalation Contacts
1. On-call engineer (PagerDuty)
2. Team lead
3. Engineering manager
4. VP Engineering (P1 only)

## Post-Incident
1. Stabilize the system
2. Document timeline
3. Identify root cause
4. Write post-mortem
5. Create action items
6. Share learnings
