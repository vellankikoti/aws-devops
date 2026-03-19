# Day 7: Production Readiness & Cost Optimization

**Theme: "Making It Real"**

**Time:** 7-8 hours | **Cost:** ~$3.50/day | **Level:** Advanced

---

## My Take: The Day Production Went Down and What I Learned

Production is a different beast. In dev, things break and you fix them during business hours with coffee. In production, things break at 2 AM on a Saturday, and thousands of users are affected.

At TransUnion, we learned this the hard way. Our Kubernetes cluster was humming along beautifully - until a single AZ went down. We hadn't configured multi-AZ properly. We hadn't tested our DR plan. We hadn't set up proper auto-scaling. 4 hours of downtime. Lessons learned.

Today is about taking everything you've built in Days 1-6 and making it production-worthy:
- **Security** that passes audits
- **High availability** that survives failures
- **Disaster recovery** that works when tested
- **Cost optimization** that keeps the CFO happy

---

## Morning Session: Security Hardening (2 hours)

### IAM Policy Refinement

The #1 security rule: **Least Privilege**. Every service gets exactly the permissions it needs, nothing more.

See our IAM policies in `security/iam-policies/`:
- `least-privilege-ec2.json` - EC2 with minimal permissions
- `least-privilege-s3.json` - S3 read-only access
- `cicd-pipeline-role.json` - Jenkins CI/CD role

### Security Audit

```bash
chmod +x security/audit-script.sh
./security/audit-script.sh
```

This checks:
- IAM users without MFA
- Publicly accessible S3 buckets
- Security groups with 0.0.0.0/0
- Unencrypted EBS volumes
- Root account usage

### Secrets Management

```bash
# Store secrets in AWS Secrets Manager
aws secretsmanager create-secret \
  --name sockshop/db-password \
  --secret-string '{"username":"admin","password":"SecurePass123!"}'

# Retrieve in your application
aws secretsmanager get-secret-value --secret-id sockshop/db-password
```

> **Production Tip:** Never store secrets in:
> - Environment variables (visible in `ps`)
> - Git repos (even private ones)
> - Terraform state (use `sensitive = true`)
> Use AWS Secrets Manager or Vault. Always.

---

## Afternoon Session: High Availability & Disaster Recovery (3 hours)

### Multi-AZ Deployment

See `ha-dr/multi-az/rds-multi-az.tf` for Multi-AZ RDS configuration.

### Auto Scaling Groups

See `ha-dr/autoscaling/asg-config.tf`:
- Launch Template with user data
- ASG across 2 AZs
- Target tracking scaling (CPU 70%)
- Step scaling for rapid response

### Disaster Recovery

Read our complete DR runbook: `ha-dr/disaster-recovery/dr-runbook.md`

Key DR strategies:
- **RTO** (Recovery Time Objective): 30 minutes
- **RPO** (Recovery Point Objective): 1 hour
- Automated backups to S3
- Cross-region replication for critical data

### Chaos Engineering

```bash
chmod +x ha-dr/chaos/chaos-experiments.sh
./ha-dr/chaos/chaos-experiments.sh
```

**Experiment 1:** Kill an EC2 instance. Watch ASG replace it.
**Experiment 2:** Block database access. Watch application handle it.
**Experiment 3:** Simulate high CPU. Watch HPA scale out.

> **Real Talk:** At TransUnion, we run chaos experiments monthly. Not because we enjoy breaking things (okay, maybe a little), but because untested DR plans are just wishes.

---

## Evening Session: Cost Optimization (2 hours)

### AWS Cost Explorer

```bash
chmod +x cost-optimization/cost-analysis.sh
./cost-optimization/cost-analysis.sh
```

### Resource Tagging Strategy

Every resource must have:
- `Project` - Which project (SockShop)
- `Environment` - dev/staging/prod
- `Owner` - Team/person responsible
- `ManagedBy` - Terraform/Manual
- `CostCenter` - For billing

See `cost-optimization/tagging-strategy.md`

### Cost Optimization Techniques

1. **Right-sizing** - Don't use m5.xlarge when t3.micro works
2. **Reserved Instances** - 40-60% savings for steady-state workloads
3. **Spot Instances** - 60-90% savings for fault-tolerant workloads
4. **Scheduled scaling** - Scale down at night, scale up in morning
5. **Delete unused resources** - EBS volumes, old snapshots, idle LBs

### Master Cleanup

```bash
chmod +x cost-optimization/cleanup-all.sh
./cost-optimization/cleanup-all.sh
```

---

## What's Next After 7 Days?

### Certification Path
1. **AWS Solutions Architect Associate** - You're 70% ready
2. **AWS DevOps Engineer Professional** - You're 60% ready
3. **CKA (Certified Kubernetes Administrator)** - Day 5 gave you a head start

### Advanced Topics to Explore
- **GitOps** with ArgoCD or Flux
- **Service Mesh** with Istio
- **Serverless** with Lambda and API Gateway
- **Multi-account** with AWS Organizations
- **Advanced networking** with Transit Gateway

### Career Path
- Junior DevOps → **You are here**
- DevOps Engineer → Focus on automation depth
- Senior DevOps → Architecture and mentoring
- Platform Engineer → Build internal developer platforms
- SRE → Reliability at scale

---

## Interactive Exercises

### Challenge 1: Security Audit
Run the security audit script. Fix every finding.

### Challenge 2: Chaos Test
Kill a critical pod. Verify the system self-heals.

### Challenge 3: Cost Report
Generate a cost report and identify 3 optimization opportunities.

---

## Deeper Learning Resources

- [AWS Well-Architected Labs](https://github.com/aws/aws-well-architected-labs) - Official labs
- [Prowler](https://github.com/toniblyx/prowler) - AWS security assessment
- [Open Guide to AWS](https://github.com/open-guides/og-aws) - Community knowledge base
- [AWS Cost Optimization Hub](https://aws.amazon.com/aws-cost-management/) - Official tools

---

## Final Cleanup

```bash
# Clean up ALL resources from all 7 days
chmod +x cost-optimization/cleanup-all.sh
./cost-optimization/cleanup-all.sh
```

---

**Congratulations!** You've completed the AWS DevOps 7-Day Journey. You now have:
- 7 real-world projects in your portfolio
- Production-grade AWS infrastructure skills
- Hands-on experience with Terraform, Ansible, Jenkins, Kubernetes, Prometheus, and Grafana
- Understanding of security, HA, DR, and cost optimization

You're not just a DevOps practitioner anymore. You're an AWS DevOps engineer who actually knows what they're doing.

Now go build something amazing.

-Koti
