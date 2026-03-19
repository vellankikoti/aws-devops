# CloudWatch Monitoring Setup - Detailed Guide

## What We're Building

A complete monitoring setup for our Day 1 infrastructure:
- **CloudWatch Dashboard**: Single pane of glass for all metrics
- **CloudWatch Alarms**: Automated alerts when things go wrong
- **Cost Monitoring**: Budget alerts and daily cost tracking
- **Log Monitoring**: Understanding where to find logs

## Why Monitoring Matters

A story from the trenches: At TransUnion, we once had a memory leak in a microservice. It consumed memory slowly - 0.5% per hour. Without monitoring, no one noticed for 3 days. Then at 2 AM on a Saturday, the service crashed, taking down the order pipeline.

With proper monitoring and alerts, we would have caught it in the first hour.

**Rule of thumb**: If you can't measure it, you can't manage it. If you can't alert on it, you'll find out from angry users.

## Prerequisites

- [ ] All Day 1 resources deployed (EC2, RDS, ALB)
- [ ] Sock Shop accessible via ALB DNS name
- [ ] AWS CLI configured

## Part 1: CloudWatch Dashboard

### Step 1: Create Dashboard via Console

1. Navigate to **CloudWatch Console** (search "CloudWatch")
2. In left sidebar, click **"Dashboards"**
3. Click **"Create dashboard"**
4. Dashboard name: `sockshop-day1`
5. Click **"Create dashboard"**

### Step 2: Add EC2 CPU Widget

1. Click **"Add widget"**
2. Select **"Line"** chart
3. Select **"Metrics"**
4. Navigate: **EC2 → Per-Instance Metrics**
5. Find your instance (search by instance ID or name)
6. Select **CPUUtilization**
7. Click **"Create widget"**

### Step 3: Add EC2 Network Widget

1. Click **"Add widget"** → **Line** → **Metrics**
2. Navigate: **EC2 → Per-Instance Metrics**
3. Select: **NetworkIn** and **NetworkOut** for your instance
4. Click **"Create widget"**

### Step 4: Add RDS Widgets

1. Click **"Add widget"** → **Line** → **Metrics**
2. Navigate: **RDS → Per-Database Metrics**
3. Select for `sockshop-db`:
   - **CPUUtilization** (database CPU)
   - **DatabaseConnections** (active connections)
   - **FreeStorageSpace** (disk remaining)
4. Click **"Create widget"**

### Step 5: Add ALB Widgets

1. Click **"Add widget"** → **Number** → **Metrics**
2. Navigate: **ApplicationELB → Per AppELB Metrics**
3. Select for `sockshop-alb`:
   - **RequestCount** (total requests)
   - **TargetResponseTime** (latency)
   - **HTTPCode_Target_2XX_Count** (successful responses)
   - **UnHealthyHostCount** (unhealthy targets)
4. Click **"Create widget"**

### Step 6: Save Dashboard

Click **"Save dashboard"** in the top right.

**Your dashboard now shows**:
- EC2 CPU usage and network traffic
- RDS database performance and connections
- ALB request volume, latency, and health

### Create Dashboard via CLI (Alternative)

```bash
# Get resource identifiers
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=sockshop-app-server" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' --output text)

ALB_SUFFIX=$(aws elbv2 describe-load-balancers \
  --names sockshop-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text | sed 's/.*:loadbalancer\///')

cat > /tmp/dashboard.json << 'DASHBOARD'
{
  "widgets": [
    {
      "type": "metric",
      "x": 0, "y": 0, "width": 12, "height": 6,
      "properties": {
        "title": "EC2 CPU Utilization",
        "metrics": [["AWS/EC2", "CPUUtilization", "InstanceId", "INSTANCE_ID"]],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1"
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 0, "width": 12, "height": 6,
      "properties": {
        "title": "ALB Request Count",
        "metrics": [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "ALB_SUFFIX"]],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1"
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 6, "width": 12, "height": 6,
      "properties": {
        "title": "RDS Database Connections",
        "metrics": [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "sockshop-db"]],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1"
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 6, "width": 12, "height": 6,
      "properties": {
        "title": "ALB Target Response Time",
        "metrics": [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "ALB_SUFFIX"]],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1"
      }
    }
  ]
}
DASHBOARD

# Replace placeholders
sed -i "s/INSTANCE_ID/$INSTANCE_ID/g" /tmp/dashboard.json
sed -i "s|ALB_SUFFIX|$ALB_SUFFIX|g" /tmp/dashboard.json

# Create the dashboard
aws cloudwatch put-dashboard \
  --dashboard-name sockshop-day1 \
  --dashboard-body file:///tmp/dashboard.json

echo "Dashboard created: sockshop-day1"
```

## Part 2: CloudWatch Alarms

Alarms notify you when metrics cross thresholds. We'll create the essential ones.

### Alarm 1: High EC2 CPU

**Why**: If CPU is consistently high, the application may be struggling or under attack.

#### Via Console

1. Navigate to **CloudWatch → Alarms → Create alarm**
2. **Select metric**: EC2 → Per-Instance Metrics → Your Instance → CPUUtilization
3. **Conditions**:
   - Threshold type: Static
   - Whenever CPUUtilization is: **Greater than 80**
   - Datapoints: 2 out of 2 (consecutive high readings)
4. **Actions**:
   - Alarm state trigger: In alarm
   - Create new SNS topic: `sockshop-alerts`
   - Email endpoint: your email
5. **Name**: `sockshop-ec2-high-cpu`
6. Click **"Create alarm"**
7. **Check your email** and confirm the SNS subscription

#### Via CLI

```bash
# Create SNS topic for alerts
TOPIC_ARN=$(aws sns create-topic \
  --name sockshop-alerts \
  --query 'TopicArn' --output text)

# Subscribe your email
aws sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol email \
  --notification-endpoint your-email@example.com

echo "Check your email and confirm the subscription!"

# Create CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name sockshop-ec2-high-cpu \
  --alarm-description "Alert when EC2 CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=InstanceId,Value=$INSTANCE_ID \
  --alarm-actions $TOPIC_ARN \
  --tags Key=Project,Value=SockShop

echo "CPU alarm created"
```

### Alarm 2: ALB Unhealthy Hosts

**Why**: If targets become unhealthy, users can't access the application.

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name sockshop-alb-unhealthy-hosts \
  --alarm-description "Alert when any ALB target is unhealthy" \
  --metric-name UnHealthyHostCount \
  --namespace AWS/ApplicationELB \
  --statistic Maximum \
  --period 60 \
  --threshold 0 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=LoadBalancer,Value=$ALB_SUFFIX \
  --alarm-actions $TOPIC_ARN \
  --tags Key=Project,Value=SockShop

echo "Unhealthy hosts alarm created"
```

### Alarm 3: ALB High Latency

**Why**: High response time means poor user experience.

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name sockshop-alb-high-latency \
  --alarm-description "Alert when ALB response time exceeds 2 seconds" \
  --metric-name TargetResponseTime \
  --namespace AWS/ApplicationELB \
  --statistic Average \
  --period 300 \
  --threshold 2 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=LoadBalancer,Value=$ALB_SUFFIX \
  --alarm-actions $TOPIC_ARN \
  --tags Key=Project,Value=SockShop

echo "Latency alarm created"
```

### Alarm 4: RDS Storage Low

**Why**: If the database runs out of storage, it stops accepting writes.

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name sockshop-rds-low-storage \
  --alarm-description "Alert when RDS free storage drops below 2GB" \
  --metric-name FreeStorageSpace \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 2000000000 \
  --comparison-operator LessThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=DBInstanceIdentifier,Value=sockshop-db \
  --alarm-actions $TOPIC_ARN \
  --tags Key=Project,Value=SockShop

echo "RDS storage alarm created"
```

### Verify Alarms

```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix sockshop \
  --query 'MetricAlarms[*].[AlarmName,StateValue]' \
  --output table
```

All alarms should show state `OK` (or `INSUFFICIENT_DATA` if newly created).

## Part 3: Cost Monitoring

### Set Up Zero Spend Budget (If Not Done)

```bash
# Create a budget via CLI
cat > /tmp/budget.json << 'EOF'
{
  "BudgetName": "sockshop-daily-budget",
  "BudgetLimit": {
    "Amount": "1",
    "Unit": "USD"
  },
  "BudgetType": "COST",
  "TimeUnit": "DAILY"
}
EOF

cat > /tmp/notifications.json << 'EOF'
[
  {
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80
    },
    "Subscribers": [
      {
        "SubscriptionType": "EMAIL",
        "Address": "your-email@example.com"
      }
    ]
  }
]
EOF

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws budgets create-budget \
  --account-id $ACCOUNT_ID \
  --budget file:///tmp/budget.json \
  --notifications-with-subscribers file:///tmp/notifications.json

echo "Daily budget alert created"
```

### Daily Cost Check

Use the provided script:

```bash
# From the repository root
./day1-foundations/scripts/check-costs.sh
```

Or quick manual check:

```bash
# Current month costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
  --output text

# Costs by service
aws ce get-cost-and-usage \
  --time-period Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[0].Groups[*].[Keys[0],Metrics.UnblendedCost.Amount]' \
  --output table
```

## Part 4: Log Monitoring

### Where to Find Logs

| Resource | Log Location | How to Access |
|----------|-------------|---------------|
| EC2 system | /var/log/syslog (Ubuntu) or /var/log/messages (AL2023) | SSH + cat/tail |
| EC2 user data | /var/log/cloud-init-output.log | SSH + cat |
| Docker containers | Docker daemon | `docker logs <container>` |
| Sock Shop services | Docker Compose | `docker-compose logs <service>` |
| RDS | RDS Console → Logs & events | Console or CLI |
| ALB | Access logs (if enabled) | S3 bucket |

### View Sock Shop Logs on EC2

```bash
# SSH into your instance
ssh -i ~/.ssh/sockshop-key.pem ubuntu@YOUR_IP

# View all service logs
cd ~/microservices-demo/deploy/docker-compose
docker-compose logs --tail=20

# View specific service
docker-compose logs --tail=50 front-end
docker-compose logs --tail=50 catalogue
docker-compose logs --tail=50 orders

# Follow logs in real-time
docker-compose logs -f front-end
# Ctrl+C to stop following
```

### Check EC2 System Logs via CLI

```bash
# Get system log output (useful for debugging boot issues)
aws ec2 get-console-output \
  --instance-id $INSTANCE_ID \
  --query 'Output' --output text | tail -50
```

## Part 5: Tag All Resources

Proper tagging is essential for cost tracking and resource management.

### Verify Tags

```bash
# Check EC2 tags
aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].Tags' --output table

# Check RDS tags
aws rds list-tags-for-resource \
  --resource-name $(aws rds describe-db-instances \
    --db-instance-identifier sockshop-db \
    --query 'DBInstances[0].DBInstanceArn' --output text)
```

### Add Missing Tags

```bash
# Tag EC2 instance
aws ec2 create-tags --resources $INSTANCE_ID \
  --tags Key=Project,Value=SockShop Key=Environment,Value=learning Key=Day,Value=1

# Tag ALB
aws elbv2 add-tags \
  --resource-arns $ALB_ARN \
  --tags Key=Project,Value=SockShop Key=Environment,Value=learning Key=Day,Value=1
```

## Daily Monitoring Checklist

Use this checklist every day during the 7-day program:

### Morning (2 minutes)
- [ ] Check CloudWatch dashboard - any anomalies overnight?
- [ ] Check alarm states - all OK?
- [ ] Check billing dashboard - any unexpected charges?

### Evening (2 minutes)
- [ ] Review daily cost in billing dashboard
- [ ] Check Free Tier usage percentages
- [ ] Decide: keep resources running or clean up for the night?

### Weekly
- [ ] Review total weekly spend
- [ ] Check for any unused/forgotten resources
- [ ] Run `./scripts/check-costs.sh` for detailed breakdown

## What You Learned

- CloudWatch dashboards for visibility
- CloudWatch alarms for proactive alerting
- SNS topics for notification delivery
- AWS cost monitoring and budgets
- Where to find logs for different services
- Resource tagging best practices

## Day 1 Complete!

You've built a complete, production-style infrastructure on AWS:

```
Internet → ALB (sockshop-alb)
              → EC2 (sockshop-app-server)
                   → Docker (Sock Shop - 14 containers)
              → RDS (sockshop-db - private subnet)
         → CloudWatch (monitoring + alarms)
         → SNS (alert notifications)
         → Budgets (cost alerts)
```

**What to do now:**
1. Run the verification script: `./scripts/verify-deployment.sh`
2. Browse Sock Shop via the ALB DNS name
3. Check your CloudWatch dashboard
4. Review cost monitoring

**Tomorrow (Day 2)**: We automate ALL of this with Terraform. Everything you spent 7 hours doing today will take 5 minutes with `terraform apply`.

---

**Time spent**: ~30-40 minutes
**Total Day 1 cost**: ~$0.50 (ALB only)
**Alarms configured**: 4 (CPU, unhealthy hosts, latency, storage)
**Dashboard widgets**: 4+ metrics across EC2, RDS, ALB
