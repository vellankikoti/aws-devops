# Day 1 Architecture - Sock Shop on AWS

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│                      Region: us-east-1                           │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    VPC: 10.0.0.0/16                        │ │
│  │                     (sockshop-vpc)                         │ │
│  │                                                             │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │          Availability Zone: us-east-1a               │ │ │
│  │  │                                                       │ │ │
│  │  │  ┌─────────────────────────────────────────────┐    │ │ │
│  │  │  │  Public Subnet: 10.0.1.0/24                 │    │ │ │
│  │  │  │                                              │    │ │ │
│  │  │  │  ┌──────────────────────────────────────┐  │    │ │ │
│  │  │  │  │  Application Load Balancer           │  │    │ │ │
│  │  │  │  │  (sockshop-alb)                      │  │    │ │ │
│  │  │  │  │  Security Group: sockshop-alb-sg     │  │    │ │ │
│  │  │  │  │  Port 80 (HTTP) ← Internet           │  │    │ │ │
│  │  │  │  └──────────────────────────────────────┘  │    │ │ │
│  │  │  │               │                             │    │ │ │
│  │  │  │               │ Port 8079                   │    │ │ │
│  │  │  │               ▼                             │    │ │ │
│  │  │  │  ┌──────────────────────────────────────┐  │    │ │ │
│  │  │  │  │  EC2 Instance: t2.micro              │  │    │ │ │
│  │  │  │  │  (sockshop-app-server)               │  │    │ │ │
│  │  │  │  │  Security Group: sockshop-ec2-sg     │  │    │ │ │
│  │  │  │  │                                       │  │    │ │ │
│  │  │  │  │  Docker + Docker Compose             │  │    │ │ │
│  │  │  │  │  ┌─────────────────────────────┐     │  │    │ │ │
│  │  │  │  │  │  Sock Shop Containers       │     │  │    │ │ │
│  │  │  │  │  │  - front-end (8079)         │     │  │    │ │ │
│  │  │  │  │  │  - catalogue + MySQL        │     │  │    │ │ │
│  │  │  │  │  │  - carts + MongoDB          │     │  │    │ │ │
│  │  │  │  │  │  - orders + MongoDB         │     │  │    │ │ │
│  │  │  │  │  │  - payment                  │     │  │    │ │ │
│  │  │  │  │  │  - shipping                 │     │  │    │ │ │
│  │  │  │  │  │  - user + MongoDB           │     │  │    │ │ │
│  │  │  │  │  │  - queue-master + RabbitMQ  │     │  │    │ │ │
│  │  │  │  │  └─────────────────────────────┘     │  │    │ │ │
│  │  │  │  └──────────────────────────────────────┘  │    │ │ │
│  │  │  └─────────────────────────────────────────────┘    │ │ │
│  │  │                                                       │ │ │
│  │  │  ┌─────────────────────────────────────────────┐    │ │ │
│  │  │  │  Private Subnet: 10.0.3.0/24                │    │ │ │
│  │  │  │                                              │    │ │ │
│  │  │  │  ┌──────────────────────────────────────┐  │    │ │ │
│  │  │  │  │  RDS MySQL: db.t3.micro              │  │    │ │ │
│  │  │  │  │  (sockshop-db)                       │  │    │ │ │
│  │  │  │  │  Security Group: sockshop-rds-sg     │  │    │ │ │
│  │  │  │  │  Port 3306 ← EC2 only                │  │    │ │ │
│  │  │  │  └──────────────────────────────────────┘  │    │ │ │
│  │  │  │           ▲                                 │    │ │ │
│  │  │  │           │ Port 3306                       │    │ │ │
│  │  │  │           │ (from EC2)                      │    │ │ │
│  │  │  └─────────────────────────────────────────────┘    │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │                                                             │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │          Availability Zone: us-east-1b               │ │ │
│  │  │                                                       │ │ │
│  │  │  Public Subnet: 10.0.2.0/24 (ALB standby)           │ │ │
│  │  │  Private Subnet: 10.0.4.0/24 (RDS standby)          │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │                                                             │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │  Internet Gateway                                    │ │ │
│  │  │  (attached to VPC)                                   │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  CloudWatch Monitoring                                     │ │
│  │  - EC2 Metrics (CPU, Network, Disk)                       │ │
│  │  - RDS Metrics (Connections, CPU, Storage)                │ │
│  │  - ALB Metrics (Requests, Response Time, Targets)         │ │
│  │  - Alarms: CPU > 80%, Unhealthy Targets                   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

Internet Users
      │
      ▼
  Port 80 (HTTP)
```

## Network Flow

### User Request Flow

1. **User → ALB**: User accesses `http://sockshop-alb-xxxxx.us-east-1.elb.amazonaws.com`
2. **ALB → Target Group**: ALB checks target group health
3. **ALB → EC2 Instance**: Forwards request to healthy EC2 instance on port 8079
4. **EC2 → Docker**: Request reaches Docker container (front-end service)
5. **Containers → Internal Communication**: Microservices communicate internally
6. **Containers → RDS**: Database queries go to RDS MySQL (for catalog data)
7. **Response Flow**: Reversed back to user

### Security Layers

**Layer 1 - ALB Security Group (sockshop-alb-sg)**
- Inbound: Port 80 from 0.0.0.0/0 (Internet)
- Outbound: All traffic allowed

**Layer 2 - EC2 Security Group (sockshop-ec2-sg)**
- Inbound:
  - Port 22 (SSH) from My IP only
  - Port 8079 from sockshop-alb-sg only
- Outbound: All traffic allowed

**Layer 3 - RDS Security Group (sockshop-rds-sg)**
- Inbound: Port 3306 from sockshop-ec2-sg only
- Outbound: All traffic allowed

### Data Flow

```
User Data:
Internet → ALB → EC2 → Application Containers → MongoDB (in container)

Product Catalog:
Internet → ALB → EC2 → Catalogue Service → RDS MySQL (managed)

Monitoring Data:
EC2/RDS/ALB → CloudWatch Metrics → CloudWatch Dashboard/Alarms
```

## Components Details

### VPC Configuration

| Component | Value | Purpose |
|-----------|-------|---------|
| VPC CIDR | 10.0.0.0/16 | Private IP range (65,536 addresses) |
| Public Subnet 1 | 10.0.1.0/24 | ALB and EC2 in AZ-1a (256 addresses) |
| Public Subnet 2 | 10.0.2.0/24 | ALB standby in AZ-1b (256 addresses) |
| Private Subnet 1 | 10.0.3.0/24 | RDS in AZ-1a (256 addresses) |
| Private Subnet 2 | 10.0.4.0/24 | RDS standby in AZ-1b (256 addresses) |
| Internet Gateway | 1 | Allows public internet access |
| Route Tables | 2 | Public (0.0.0.0/0 → IGW), Private (local only) |

### Compute Resources

| Resource | Type | Purpose | Cost |
|----------|------|---------|------|
| EC2 Instance | t2.micro | Docker host for Sock Shop | $0 (Free Tier) |
| AMI | Amazon Linux 2023 | Base OS with Docker support | $0 |
| EBS Volume | 8 GB gp3 | Root volume for instance | $0 (Free Tier) |
| Public IP | Elastic IP | Internet access | $0 (while attached) |

### Database Resources

| Resource | Type | Purpose | Cost |
|----------|------|---------|------|
| RDS MySQL | db.t3.micro | Managed MySQL for catalog | $0 (Free Tier) |
| Storage | 20 GB gp3 | Database storage | $0 (Free Tier) |
| Multi-AZ | Disabled | Cost savings (not HA) | $0 |
| Backups | Disabled | Cost savings | $0 |

### Load Balancing

| Resource | Type | Purpose | Cost |
|----------|------|---------|------|
| ALB | Application LB | HTTP load balancing | ~$0.50/day |
| Target Group | Instance type | Routes to EC2 instances | $0 |
| Health Checks | HTTP on / | Monitors target health | $0 |
| Listeners | Port 80 HTTP | Accepts user traffic | $0 |

### Microservices Architecture

The Sock Shop application consists of 8 microservices:

1. **front-end** (Port 8079)
   - User interface (web UI)
   - Node.js application
   - Entry point for users

2. **catalogue** + **catalogue-db**
   - Product catalog service (Go)
   - MySQL database (containerized for now)
   - Stores product information

3. **carts** + **carts-db**
   - Shopping cart service (Java)
   - MongoDB database (containerized)
   - Manages user shopping carts

4. **orders** + **orders-db**
   - Order processing service (Java)
   - MongoDB database (containerized)
   - Handles order placement

5. **payment**
   - Payment processing service (Go)
   - Simulated payment gateway
   - Processes transactions

6. **shipping**
   - Shipping calculation service (Java)
   - Calculates shipping costs
   - Manages delivery estimates

7. **user** + **user-db**
   - User authentication service (Go)
   - MongoDB database (containerized)
   - Handles login/registration

8. **queue-master** + **rabbitmq**
   - Message queue service (Java)
   - RabbitMQ message broker
   - Asynchronous task processing

## Monitoring Setup

### CloudWatch Metrics Collected

**EC2 Metrics** (every 5 minutes):
- CPUUtilization
- NetworkIn / NetworkOut
- DiskReadBytes / DiskWriteBytes
- StatusCheckFailed

**RDS Metrics** (every 1 minute):
- CPUUtilization
- DatabaseConnections
- FreeStorageSpace
- ReadLatency / WriteLatency

**ALB Metrics** (every 1 minute):
- RequestCount
- TargetResponseTime
- HealthyHostCount / UnHealthyHostCount
- HTTPCode_Target_2XX_Count (success)
- HTTPCode_Target_5XX_Count (errors)

### Alarms Configured

1. **EC2 High CPU**
   - Threshold: > 80%
   - Period: 5 minutes
   - Action: SNS notification

2. **Unhealthy Targets**
   - Threshold: > 0 unhealthy
   - Period: 2 minutes
   - Action: SNS notification

3. **RDS High Connections** (optional)
   - Threshold: > 50 connections
   - Period: 5 minutes
   - Action: SNS notification

## Cost Breakdown

### Daily Costs

| Service | Usage | Free Tier Limit | Daily Cost |
|---------|-------|-----------------|------------|
| EC2 t2.micro | 24 hours | 750 hours/month | $0.00 |
| RDS db.t3.micro | 24 hours | 750 hours/month | $0.00 |
| EBS 8 GB | 8 GB | 30 GB | $0.00 |
| Application Load Balancer | 24 hours | None | ~$0.50 |
| Data Transfer Out | < 1 GB | 15 GB/month | $0.00 |
| CloudWatch Metrics | Basic | Free | $0.00 |
| **Total** | | | **~$0.50** |

### Weekly Cost (7 days)

- Total: ~$3.50
- All from ALB (only non-free tier service)

### Monthly Cost Projection

If running 24/7 for a month:
- ALB: ~$15
- EC2: $0 (Free Tier)
- RDS: $0 (Free Tier)
- **Total: ~$15/month**

### Cost Optimization Tips

1. **Stop resources when not in use**:
   ```bash
   # Stop EC2 (doesn't delete, just stops)
   aws ec2 stop-instances --instance-ids i-xxxxx

   # Stop RDS (creates snapshot, then stops)
   aws rds stop-db-instance --db-instance-identifier sockshop-db
   ```

2. **Delete ALB when testing**:
   - ALB costs money even with no traffic
   - Can recreate easily with Terraform (Day 2)

3. **Use cleanup script**:
   ```bash
   ./scripts/cleanup-day1.sh
   ```

## High Availability Considerations

### Current Setup (Day 1)

- ✓ VPC spans 2 Availability Zones
- ✓ ALB distributes across 2 AZs
- ✗ Only 1 EC2 instance (single point of failure)
- ✗ RDS in single-AZ mode (cost savings)

### Production Setup (Future)

- Multiple EC2 instances across AZs
- Auto Scaling Group for automatic scaling
- RDS Multi-AZ for automatic failover
- EBS snapshots for backup
- Route 53 for DNS with health checks

## Security Considerations

### Implemented Security

✓ **Network Isolation**:
- Private subnets for databases (no internet access)
- Security groups with least privilege

✓ **Access Control**:
- SSH only from specific IP
- Database only from EC2
- ALB only on port 80

✓ **IAM**:
- Root account has MFA
- Using IAM user for daily work
- Proper access key management

✓ **Monitoring**:
- CloudWatch alarms for anomalies
- Billing alerts for unexpected costs

### Missing (For Production)

- HTTPS/TLS encryption (need ACM certificate)
- WAF (Web Application Firewall)
- VPC Flow Logs
- GuardDuty threat detection
- Secrets Manager for credentials
- IAM roles for EC2 (instead of access keys)

## Disaster Recovery

### Current Backup Strategy

- RDS automated backups: Disabled (cost savings)
- EC2 instance: No automated snapshots
- Application data: In containers (ephemeral)

### Recovery Time

- If EC2 instance dies: ~15 minutes (manual recreation)
- If RDS dies: Data loss (no backups)
- If AZ fails: Partial outage (only 1 instance)

### Production Recommendations

1. Enable RDS automated backups (7 days retention)
2. EBS snapshots daily
3. Multi-AZ deployment
4. Disaster recovery runbook
5. Regular disaster recovery testing

## Next Steps (Day 2)

Tomorrow, we automate this entire architecture with Terraform:

- VPC and subnets → Terraform modules
- EC2 instances → Auto Scaling Groups
- RDS → With proper backups
- Security groups → As code
- CloudWatch → Automated dashboard creation
- **Deployment time**: 5 minutes (vs 7 hours manual)

## Troubleshooting Guide

### Can't Access Sock Shop

1. Check ALB DNS is correct
2. Verify target health: `./scripts/verify-deployment.sh`
3. Check security groups (port 8079 from ALB)
4. SSH to EC2 and verify containers: `docker ps`

### RDS Connection Failed

1. Verify security group allows port 3306 from EC2 SG
2. Check RDS is in "available" state
3. Verify endpoint is correct
4. Test from EC2: `mysql -h endpoint -u admin -p`

### High Costs

1. Run: `./scripts/check-costs.sh`
2. Check for non-Free Tier instance types
3. Verify no extra instances running
4. Stop or delete unused resources

### SSH Connection Timeout

1. Verify security group allows port 22 from your IP
2. Check instance has public IP
3. Verify key permissions: `chmod 400 key.pem`
4. Try from AWS Console: Session Manager

---

**Architecture Designed By**: Koti
**Date**: 2025-12-28
**Version**: 1.0 - Day 1 Manual Deployment
**Next Version**: Day 2 - Terraform Automation
