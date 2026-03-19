# Application Load Balancer Setup - Detailed Guide

## What We're Building

A production-grade load balancer in front of our Sock Shop application:
- **Type**: Application Load Balancer (Layer 7 - HTTP/HTTPS)
- **Scheme**: Internet-facing (accessible from the public internet)
- **AZs**: Deployed across 2 Availability Zones (high availability)
- **Health Checks**: Automatically detects unhealthy targets

```
Internet
   │
   ▼
┌──────────────────────────┐
│  Application Load        │
│  Balancer (ALB)          │
│  sockshop-alb            │
│  Port 80 (HTTP)          │
│  DNS: sockshop-alb-      │
│    xxxx.elb.amazonaws.com│
└──────────┬───────────────┘
           │ Port 8079
           ▼
┌──────────────────────────┐
│  Target Group            │
│  sockshop-tg             │
│  Health: HTTP / /        │
│                          │
│  ┌────────────────────┐  │
│  │ EC2: sockshop-app  │  │
│  │ Port 8079          │  │
│  └────────────────────┘  │
└──────────────────────────┘
```

## Why Use a Load Balancer?

Even with a single EC2 instance, an ALB provides:

1. **Stable DNS endpoint**: EC2 public IPs change on restart; ALB DNS name doesn't
2. **Health checks**: ALB monitors instance health and can stop sending traffic to failing instances
3. **SSL/TLS termination**: Add HTTPS easily (with ACM certificate)
4. **Future scaling**: When you add more instances, ALB distributes traffic automatically
5. **Security**: Hide your EC2 directly behind the ALB

**Cost**: ALB is the one non-free-tier service today (~$0.50/day). It's worth it to learn the real way.

## Prerequisites

- [ ] EC2 instance running Sock Shop ([04-sockshop-deployment.md](./04-sockshop-deployment.md))
- [ ] Sock Shop accessible on port 8079 from the instance
- [ ] You know your VPC ID and public subnet IDs

## Step 1: Create Target Group

Target groups define WHERE the ALB sends traffic.

### Via Console

1. Navigate to **EC2 Console → Target Groups** (under "Load Balancing" in left sidebar)
2. Click **"Create target group"**
3. Basic configuration:
   - **Target type**: Instances
   - **Target group name**: `sockshop-tg`
   - **Protocol / Port**: HTTP / 8079
   - **VPC**: `sockshop-vpc`
   - **Protocol version**: HTTP1

4. Health checks:
   - **Health check protocol**: HTTP
   - **Health check path**: `/`
   - Click **"Advanced health check settings"**:
     - **Healthy threshold**: 2 (2 consecutive successes = healthy)
     - **Unhealthy threshold**: 2 (2 consecutive failures = unhealthy)
     - **Timeout**: 5 seconds
     - **Interval**: 30 seconds
     - **Success codes**: 200

5. Click **"Next"**

6. Register targets:
   - Select your `sockshop-app-server` instance
   - Ensure port is `8079`
   - Click **"Include as pending below"**
   - Verify the instance appears in the "Review targets" section

7. Click **"Create target group"**

### Via CLI

```bash
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=sockshop-vpc" \
  --query 'Vpcs[0].VpcId' --output text)

# Create target group
TG_ARN=$(aws elbv2 create-target-group \
  --name sockshop-tg \
  --protocol HTTP \
  --port 8079 \
  --vpc-id $VPC_ID \
  --health-check-protocol HTTP \
  --health-check-path "/" \
  --health-check-interval-seconds 30 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 2 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "Target Group ARN: $TG_ARN"

# Register EC2 instance
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=sockshop-app-server" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' --output text)

aws elbv2 register-targets \
  --target-group-arn $TG_ARN \
  --targets Id=$INSTANCE_ID,Port=8079

echo "Registered instance $INSTANCE_ID in target group"
```

## Step 2: Create ALB Security Group

The ALB needs its own security group - it's the public-facing entry point.

### Via Console

1. Navigate to **EC2 Console → Security Groups**
2. Click **"Create security group"**
3. Settings:
   - **Name**: `sockshop-alb-sg`
   - **Description**: `Security group for Sock Shop Application Load Balancer`
   - **VPC**: `sockshop-vpc`

4. **Inbound Rules**:

| Type | Port | Source | Description |
|------|------|--------|-------------|
| HTTP | 80 | 0.0.0.0/0 | Allow HTTP from anywhere |

5. **Outbound Rules**: Leave default (All traffic)
6. Add tag: `Key=Project, Value=SockShop`
7. Click **"Create security group"**

### Via CLI

```bash
ALB_SG=$(aws ec2 create-security-group \
  --group-name sockshop-alb-sg \
  --description "Security group for Sock Shop ALB" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

aws ec2 create-tags --resources $ALB_SG \
  --tags Key=Project,Value=SockShop Key=Name,Value=sockshop-alb-sg

echo "ALB Security Group: $ALB_SG"
```

## Step 3: Create the Application Load Balancer

### Via Console

1. Navigate to **EC2 Console → Load Balancers**
2. Click **"Create load balancer"**
3. Choose **"Application Load Balancer"** → Create

4. Basic configuration:
   - **Name**: `sockshop-alb`
   - **Scheme**: Internet-facing
   - **IP address type**: IPv4

5. Network mapping:
   - **VPC**: `sockshop-vpc`
   - **Mappings**: Check BOTH availability zones
   - For each AZ, select the **public** subnet

6. Security groups:
   - Remove the default security group
   - Select: `sockshop-alb-sg`

7. Listeners and routing:
   - **Protocol**: HTTP
   - **Port**: 80
   - **Default action**: Forward to → `sockshop-tg`

8. Add tag: `Key=Project, Value=SockShop`
9. Review and click **"Create load balancer"**

### Via CLI

```bash
# Get public subnet IDs
PUB_SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=*public*" \
  --query 'Subnets[*].SubnetId' --output text)

# Create ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name sockshop-alb \
  --subnets $PUB_SUBNETS \
  --security-groups $ALB_SG \
  --scheme internet-facing \
  --type application \
  --tags Key=Project,Value=SockShop \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

echo "ALB ARN: $ALB_ARN"

# Create listener (routes port 80 to target group)
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN

echo "Listener created"

# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --query 'LoadBalancers[0].DNSName' --output text)

echo "ALB DNS: $ALB_DNS"
echo "Access Sock Shop at: http://$ALB_DNS"
```

## Step 4: Tighten EC2 Security Group

Now that traffic flows through the ALB, restrict direct access to EC2:

### Via Console

1. Navigate to **EC2 Console → Security Groups**
2. Select `sockshop-ec2-sg`
3. Click **"Edit inbound rules"**
4. Find the rule for port **8079** with source `0.0.0.0/0`
5. Change source to: `sockshop-alb-sg` (select the ALB security group)
6. Click **"Save rules"**

**Before:**
```
Port 8079 ← 0.0.0.0/0 (anyone)
```

**After:**
```
Port 8079 ← sockshop-alb-sg (only ALB)
```

Now only the ALB can reach port 8079 on your EC2 instance. Direct browser access to `EC2_IP:8079` will stop working - that's intentional.

### Via CLI

```bash
EC2_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=sockshop-ec2-sg" \
  --query 'SecurityGroups[0].GroupId' --output text)

# Revoke the old rule (0.0.0.0/0 on port 8079)
aws ec2 revoke-security-group-ingress \
  --group-id $EC2_SG \
  --protocol tcp --port 8079 --cidr 0.0.0.0/0

# Add new rule (ALB SG only)
aws ec2 authorize-security-group-ingress \
  --group-id $EC2_SG \
  --protocol tcp --port 8079 \
  --source-group $ALB_SG

echo "EC2 security group tightened - only ALB can access port 8079"
```

## Step 5: Wait and Test

ALB takes 2-3 minutes to become active.

### Check ALB Status

```bash
# Check ALB state
aws elbv2 describe-load-balancers \
  --names sockshop-alb \
  --query 'LoadBalancers[0].State.Code' --output text
# Should show: "active"
```

### Check Target Health

```bash
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason]' \
  --output table
```

**Expected**: State = `healthy`

### Access via Browser

```bash
# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names sockshop-alb \
  --query 'LoadBalancers[0].DNSName' --output text)

echo "Open in browser: http://$ALB_DNS"
```

Open that URL in your browser. You should see the Sock Shop homepage.

## Troubleshooting

### Target shows "unhealthy"

1. **Check the application is running**: SSH into EC2 and verify `docker ps` shows containers
2. **Test locally**: `curl http://localhost:8079` on the EC2 instance
3. **Check security groups**: EC2 SG must allow port 8079 from ALB SG
4. **Check health check path**: Should be `/` on port 8079
5. Wait 1-2 minutes for health check to re-evaluate

### ALB returns "502 Bad Gateway"

- Target is registered but unhealthy
- Application is crashing or not responding
- Check EC2 instance and Docker logs

### ALB returns "503 Service Unavailable"

- No healthy targets in the target group
- All instances are unhealthy or deregistered
- Check target group and instance health

### Can't access ALB DNS in browser

1. Is the ALB "active"? Check Load Balancers in console
2. Is the ALB security group allowing port 80 from 0.0.0.0/0?
3. DNS propagation can take 1-2 minutes

## Understanding the Traffic Flow

```
1. User types: http://sockshop-alb-xxxx.elb.amazonaws.com
2. DNS resolves to ALB IP addresses (multiple, for HA)
3. ALB receives request on port 80
4. ALB checks: sockshop-alb-sg allows port 80 from 0.0.0.0/0 ✅
5. ALB forwards to healthy target in sockshop-tg on port 8079
6. EC2 checks: sockshop-ec2-sg allows port 8079 from sockshop-alb-sg ✅
7. Sock Shop front-end processes request
8. Response flows back: Sock Shop → EC2 → ALB → User
```

## Save Your Resource IDs

```
Target Group Name:   sockshop-tg
Target Group ARN:    arn:aws:elasticloadbalancing:...
ALB Name:            sockshop-alb
ALB ARN:             arn:aws:elasticloadbalancing:...
ALB DNS Name:        sockshop-alb-xxxx.us-east-1.elb.amazonaws.com
ALB Security Group:  sg-________________
```

## What You Learned

- Application Load Balancers and how they distribute traffic
- Target groups and health checks
- Security group chaining (ALB SG → EC2 SG)
- Defense in depth (restricting direct access to EC2)
- Why stable DNS endpoints matter

## Next Step

We have a working application behind a load balancer. Let's add monitoring to know when things go wrong.

**Next**: [07-monitoring-setup.md](./07-monitoring-setup.md) - Set up CloudWatch monitoring, dashboards, and alarms

---

**Time spent**: ~15-20 minutes
**Cost impact**: ALB costs ~$0.50/day (only non-free resource today)
**Resources created**: Target group, ALB security group, Application Load Balancer, listener
