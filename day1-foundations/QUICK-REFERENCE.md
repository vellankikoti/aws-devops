# Day 1 Quick Reference Guide

Fast reference for commands, IPs, and common tasks during Day 1.

## Essential Information

### Your AWS Details
```bash
# Check your AWS identity
aws sts get-caller-identity

# Your account ID: ___________________
# Your region: us-east-1 (or _________)
# IAM user: devops-admin (or _________)
```

### Resource Names to Remember

| Resource Type | Name |
|---------------|------|
| VPC | sockshop-vpc |
| EC2 Instance | sockshop-app-server |
| RDS Database | sockshop-db |
| Load Balancer | sockshop-alb |
| Target Group | sockshop-tg |
| Security Groups | sockshop-alb-sg, sockshop-ec2-sg, sockshop-rds-sg |
| SSH Key | sockshop-key |

## Quick Commands

### SSH to EC2
```bash
# Replace IP with your EC2 public IP
ssh -i ~/Downloads/sockshop-key.pem ec2-user@YOUR-EC2-IP

# Find your EC2 IP
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=sockshop-app-server" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

### Check Sock Shop Status
```bash
# SSH to EC2 first, then:

# Check running containers
docker ps

# Check container logs
docker-compose -f ~/microservices-demo/deploy/docker-compose/docker-compose.yml logs

# Restart all services
cd ~/microservices-demo/deploy/docker-compose
docker-compose down
docker-compose up -d

# Check specific service
docker logs <container-id>
```

### Access Points

**Sock Shop Application:**
```
# Via Load Balancer (recommended)
http://YOUR-ALB-DNS-NAME.elb.amazonaws.com

# Find ALB DNS
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[0].DNSName' \
  --output text

# Direct to EC2 (if ALB not working)
http://YOUR-EC2-IP:8079
```

**RDS Database:**
```bash
# From EC2 instance only (SSH first)
mysql -h YOUR-RDS-ENDPOINT -u admin -p

# Find RDS endpoint
aws rds describe-db-instances \
  --db-instance-identifier sockshop-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

## Monitoring Commands

### Check Resource Status
```bash
# EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=SockShop" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PublicIpAddress]' \
  --output table

# RDS status
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,DBInstanceClass]' \
  --output table

# ALB status
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].[LoadBalancerName,State.Code,DNSName]' \
  --output table

# Target health
aws elbv2 describe-target-health \
  --target-group-arn YOUR-TG-ARN \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' \
  --output table
```

### Check Costs
```bash
# Run cost check script
cd ~/Downloads/aws-devops/day1-foundations
./scripts/check-costs.sh

# Or manually check
aws ce get-cost-and-usage \
  --time-period Start=2025-12-01,End=2025-12-28 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
  --output text
```

## Troubleshooting

### Can't SSH to EC2
```bash
# 1. Check security group allows your IP
aws ec2 describe-security-groups \
  --group-names sockshop-ec2-sg \
  --query 'SecurityGroups[0].IpPermissions'

# 2. Update security group with current IP
MY_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress \
  --group-name sockshop-ec2-sg \
  --protocol tcp \
  --port 22 \
  --cidr ${MY_IP}/32

# 3. Check key permissions
chmod 400 ~/Downloads/sockshop-key.pem
```

### Sock Shop Not Loading
```bash
# 1. Check target health
./scripts/verify-deployment.sh

# 2. SSH to EC2 and check containers
ssh -i ~/Downloads/sockshop-key.pem ec2-user@YOUR-EC2-IP
docker ps  # Should see ~14 containers

# 3. Check logs
docker-compose -f ~/microservices-demo/deploy/docker-compose/docker-compose.yml logs front-end

# 4. Restart if needed
docker-compose down && docker-compose up -d
```

### RDS Connection Issues
```bash
# 1. Verify security group
aws ec2 describe-security-groups \
  --group-names sockshop-rds-sg \
  --query 'SecurityGroups[0].IpPermissions'

# 2. Test from EC2
ssh -i ~/Downloads/sockshop-key.pem ec2-user@YOUR-EC2-IP
mysql -h YOUR-RDS-ENDPOINT -u admin -p
```

### High CPU on EC2
```bash
# SSH to instance
ssh -i ~/Downloads/sockshop-key.pem ec2-user@YOUR-EC2-IP

# Check CPU usage
top

# Check container resource usage
docker stats

# If needed, restart heavy containers
docker restart <container-id>
```

## Resource Management

### Stop Resources (Save Money)
```bash
# Stop EC2 (instance remains, just stopped)
aws ec2 stop-instances --instance-ids YOUR-INSTANCE-ID

# Stop RDS (saves ~$0.10/day storage cost if you can wait)
aws rds stop-db-instance --db-instance-identifier sockshop-db

# ALB can't be stopped, only deleted (then you pay nothing)
```

### Start Resources (Resume Work)
```bash
# Start EC2
aws ec2 start-instances --instance-ids YOUR-INSTANCE-ID

# Start RDS
aws rds start-db-instance --db-instance-identifier sockshop-db

# Wait for them to be ready
aws ec2 wait instance-running --instance-ids YOUR-INSTANCE-ID
aws rds wait db-instance-available --db-instance-identifier sockshop-db
```

### Complete Cleanup (Delete Everything)
```bash
# Use the automated script
cd ~/Downloads/aws-devops/day1-foundations
./scripts/cleanup-day1.sh

# Or manual deletion (in this order):
# 1. Delete ALB
# 2. Delete Target Group
# 3. Terminate EC2
# 4. Delete RDS
# 5. Delete Security Groups
# 6. Delete VPC
```

## Security Group Reference

### sockshop-alb-sg (Load Balancer)
```
Inbound:
  - Port 80 (HTTP) from 0.0.0.0/0
Outbound:
  - All traffic
```

### sockshop-ec2-sg (EC2 Instance)
```
Inbound:
  - Port 22 (SSH) from My IP
  - Port 8079 (Sock Shop) from sockshop-alb-sg
  - Port 80 (HTTP) from sockshop-alb-sg (optional)
Outbound:
  - All traffic
```

### sockshop-rds-sg (RDS Database)
```
Inbound:
  - Port 3306 (MySQL) from sockshop-ec2-sg
Outbound:
  - All traffic
```

## Common AWS CLI Patterns

### Find Resource IDs
```bash
# VPC ID
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=sockshop-vpc" \
  --query 'Vpcs[0].VpcId' \
  --output text

# EC2 Instance ID
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=sockshop-app-server" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text

# ALB ARN
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?LoadBalancerName==`sockshop-alb`].LoadBalancerArn' \
  --output text

# Security Group ID
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=sockshop-ec2-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text
```

### Tag Resources
```bash
# Tag an EC2 instance
aws ec2 create-tags \
  --resources i-xxxxx \
  --tags Key=Project,Value=SockShop Key=Environment,Value=dev

# Tag RDS
aws rds add-tags-to-resource \
  --resource-name arn:aws:rds:us-east-1:xxxx:db:sockshop-db \
  --tags Key=Project,Value=SockShop
```

## Billing and Cost Alerts

### Check Free Tier Usage
```bash
# Open in browser (AWS CLI doesn't have direct command)
# Console → Billing → Free Tier

# Or use Cost Explorer API
aws ce get-cost-and-usage \
  --time-period Start=2025-12-01,End=2025-12-31 \
  --granularity MONTHLY \
  --metrics UsageQuantity \
  --group-by Type=DIMENSION,Key=SERVICE
```

### Set Budget Alerts
```bash
# Via Console (easier):
# Billing → Budgets → Create Budget

# Example: Zero spend budget
# Name: free-tier-monitor
# Amount: $0
# Alert when: Actual cost > $0.01
```

## Docker Commands on EC2

```bash
# View all containers
docker ps -a

# View only running
docker ps

# Container logs (last 100 lines)
docker logs --tail 100 <container-id>

# Follow logs (live)
docker logs -f <container-id>

# Restart a container
docker restart <container-id>

# Stop all containers
docker stop $(docker ps -q)

# Remove all stopped containers
docker container prune -f

# Check disk usage
docker system df

# Full cleanup (careful!)
docker system prune -a
```

## CloudWatch Quick Commands

```bash
# Get EC2 CPU utilization (last hour)
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=YOUR-INSTANCE-ID \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# List all alarms
aws cloudwatch describe-alarms \
  --query 'MetricAlarms[*].[AlarmName,StateValue]' \
  --output table

# Test an alarm (manually set state)
aws cloudwatch set-alarm-state \
  --alarm-name sockshop-ec2-high-cpu \
  --state-value ALARM \
  --state-reason "Testing alarm"
```

## Helpful Scripts

All scripts are in `scripts/` directory:

```bash
# Verify deployment
./scripts/verify-deployment.sh

# Check costs
./scripts/check-costs.sh

# Clean up everything
./scripts/cleanup-day1.sh
```

## Common Errors and Fixes

### Error: "VPC Not Found"
```bash
# Check you're in the right region
aws configure get region

# Set region
aws configure set region us-east-1
```

### Error: "Access Denied"
```bash
# Check your IAM user has AdministratorAccess
aws iam list-attached-user-policies --user-name devops-admin
```

### Error: "Insufficient Capacity"
```bash
# Try a different availability zone
# Or wait a few minutes and retry
```

### Error: "Target Group Has No Healthy Targets"
```bash
# 1. Check security group allows ALB → EC2 on port 8079
# 2. Check application is running: docker ps
# 3. Check health check path is correct: /
# 4. Wait 2-3 minutes for health checks to pass
```

## Daily Checklist

### Morning (When Starting Work)
- [ ] Check billing dashboard (should be ~$0.50/day)
- [ ] Start EC2 instance if stopped
- [ ] Start RDS instance if stopped
- [ ] Wait for instances to be ready
- [ ] Verify Sock Shop is accessible

### Evening (When Finishing Work)
- [ ] Run `./scripts/check-costs.sh`
- [ ] Decide: keep running or cleanup
- [ ] If keeping: verify alarms are working
- [ ] If cleaning up: run `./scripts/cleanup-day1.sh`

## Next Steps

After completing Day 1:
- [ ] Verify everything works: `./scripts/verify-deployment.sh`
- [ ] Document any issues you faced
- [ ] Take screenshots of working application
- [ ] Review architecture diagram
- [ ] Prepare for Day 2: Terraform automation

---

**Keep this file open in a tab for quick reference throughout Day 1!**

---

For detailed explanations, see: [README.md](./README.md)
For architecture details, see: [diagrams/architecture.md](./diagrams/architecture.md)
For manual steps, see: [manual-steps/](./manual-steps/)
