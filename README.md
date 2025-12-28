# AWS DevOps Mastery: Zero to Hero in 7 Days

**Learn AWS DevOps the right way: 100% hands-on, 100% practical, 100% free (almost).**

## What is This?

This is not another AWS course with boring slides and theory. This is **7 days of intense, hands-on learning** where you build real infrastructure on AWS using production-grade tools.

By Day 7, you'll have:
- Deployed a complete microservices application on AWS
- Mastered Terraform, Ansible, Jenkins, Docker, and Kubernetes
- Built a full observability stack (Prometheus, Grafana, OpenTelemetry)
- Created a portfolio of 7 real-world projects
- Understood AWS architecture at Solutions Architect level

And the best part? **Total cost: ~$20-25 for the entire 7 days** (if you keep everything running 24/7, less if you clean up daily).

## The Koti Promise

I'm Koti, a DevOps Engineer at TransUnion managing 1000+ Kubernetes workloads across 50+ clusters. I've made every mistake possible in AWS so you don't have to.

**What makes this different:**
- ✅ **No application development** - We use existing open-source apps (Sock Shop microservices)
- ✅ **No toy projects** - Everything is production-grade and follows AWS Well-Architected Framework
- ✅ **No theoretical BS** - 100% hands-on, real AWS Console and CLI work
- ✅ **No confusion** - Crystal clear instructions, tested personally by me
- ✅ **No hidden costs** - Complete transparency on every dollar spent

## Who is This For?

**You're ready for this if you:**
- Have basic Linux knowledge (our [Linux course](https://devopsengineers.in/docs/category/linux) level)
- Know basic shell scripting (our [Shell Scripting course](https://devopsengineers.in/docs/category/shell-scripting) level)
- Understand what Docker containers are (don't need to be an expert)
- Have used Git before
- Want to learn AWS the practical way, not the theoretical way

**You'll struggle if you:**
- Have never touched a terminal
- Expect copy-paste without understanding
- Want quick certifications without depth
- Aren't willing to spend 7-8 hours per day

## The 7-Day Journey

### Day 1: AWS Foundations & Manual Deployment
**Theme:** Understanding AWS the Hard Way

**What you'll build:**
- Custom VPC with public and private subnets across 2 AZs
- EC2 instance running Docker with Sock Shop microservices (14 containers)
- RDS MySQL database in private subnet
- Application Load Balancer for traffic distribution
- CloudWatch monitoring, alarms, and billing alerts

**What you'll learn:**
- AWS networking fundamentals (VPC, subnets, routing, security groups)
- EC2 instance management
- RDS managed databases
- Load balancing and high availability concepts
- Cost monitoring and Free Tier management

**Time:** 7-8 hours
**Cost:** ~$0.50 (ALB only)

👉 [Start Day 1](./day1-foundations/README.md)

### Day 2: Infrastructure as Code with Terraform
**Theme:** Automate Everything You Did Yesterday

**What you'll build:**
- Terraform modules for VPC, EC2, RDS, ALB, Security Groups
- Reusable infrastructure code
- Remote state management in S3 with DynamoDB locking
- Multi-environment setup (dev/staging/prod) with workspaces

**What you'll learn:**
- Terraform fundamentals and best practices
- Infrastructure as Code philosophy
- State management and why it matters
- Creating reusable modules
- Destroying and recreating infrastructure in minutes

**Time:** 7-8 hours
**Cost:** ~$0.50/day (same infrastructure, now automated)

👉 [Start Day 2](./day2-terraform/README.md) *(coming soon)*

### Day 3: Configuration Management with Ansible
**Theme:** Configure at Scale

**What you'll build:**
- Ansible playbooks for automated Docker installation
- Application deployment automation
- Database configuration as code
- Dynamic inventory from AWS
- Ansible Vault for secrets management

**What you'll learn:**
- Ansible fundamentals
- Configuration vs Infrastructure (Terraform vs Ansible)
- Idempotent operations
- Role-based playbook structure
- Secrets management

**Time:** 7-8 hours
**Cost:** ~$0.50/day

👉 [Start Day 3](./day3-ansible/README.md) *(coming soon)*

### Day 4: CI/CD Pipeline with Jenkins
**Theme:** Automate the Automation

**What you'll build:**
- Jenkins server on EC2
- Multi-stage CI/CD pipeline (Terraform → Ansible → Deploy → Test)
- GitHub integration
- Blue-green deployment strategy
- Automated rollback mechanisms

**What you'll learn:**
- CI/CD principles
- Pipeline as Code (Jenkinsfile)
- Deployment strategies
- GitOps workflow
- Integration with AWS services

**Time:** 7-8 hours
**Cost:** ~$1.00/day (additional EC2 for Jenkins)

👉 [Start Day 4](./day4-jenkins/README.md) *(coming soon)*

### Day 5: Container Orchestration with ECS/EKS
**Theme:** Kubernetes in the Cloud

**What you'll build:**
- EKS cluster (or ECS Fargate for free tier)
- Kubernetes manifests for Sock Shop
- Horizontal Pod Autoscaling
- Cluster Autoscaling
- Ingress configuration with ALB

**What you'll learn:**
- Kubernetes architecture and concepts
- EKS vs ECS vs self-managed K8s
- Container orchestration patterns
- Auto-scaling configurations
- Cloud-native application deployment

**Time:** 7-8 hours
**Cost:** ~$3.50/day (EKS control plane) OR $0 with ECS Fargate

👉 [Start Day 5](./day5-kubernetes/README.md) *(coming soon)*

### Day 6: Observability Stack (Prometheus, Grafana, OpenTelemetry)
**Theme:** See Everything, Know Everything

**What you'll build:**
- Prometheus for metrics collection
- Grafana with custom dashboards
- AlertManager for intelligent alerting
- OpenTelemetry Collector for distributed tracing
- Complete observability across all services

**What you'll learn:**
- The three pillars: Metrics, Logs, Traces
- Prometheus query language (PromQL)
- Building effective dashboards
- Alert fatigue prevention
- Production debugging techniques

**Time:** 7-8 hours
**Cost:** ~$3.50/day (same as Day 5)

👉 [Start Day 6](./day6-observability/README.md) *(coming soon)*

### Day 7: Production Readiness & Cost Optimization
**Theme:** Making It Real

**What you'll build:**
- Multi-AZ high availability setup
- Auto Scaling Groups
- Disaster recovery plan and runbook
- Security hardening (IAM policies, Secrets Manager)
- Cost optimization analysis

**What you'll learn:**
- Production vs Development mindset
- AWS Well-Architected Framework
- Security best practices
- Disaster recovery planning
- Cost optimization strategies

**Time:** 7-8 hours
**Cost:** ~$3.50/day

👉 [Start Day 7](./day7-production/README.md) *(coming soon)*

## Cost Breakdown

### Daily Costs (if running 24/7)

| Day | Services | Daily Cost | Notes |
|-----|----------|------------|-------|
| 1 | EC2 + RDS + ALB | ~$0.50 | Free Tier for EC2/RDS |
| 2 | Same + S3/DynamoDB | ~$0.50 | S3/DynamoDB free |
| 3 | Same | ~$0.50 | No new services |
| 4 | Add Jenkins EC2 | ~$1.00 | Extra t2.micro |
| 5 | Add EKS/ECS | ~$3.50 | EKS control plane OR $0 with ECS |
| 6 | Add monitoring | ~$3.50 | Runs on K8s |
| 7 | Same | ~$3.50 | Optimization day |

**Total for 7 days (running 24/7):** ~$20-25

### How to Keep Costs Lower

1. **Clean up daily**: Run cleanup scripts at end of each day
2. **Use ECS instead of EKS** on Day 5 (saves $15/week)
3. **Stop instances when not using**: EC2 and RDS can be stopped
4. **Delete and recreate**: With Terraform (Day 2+), recreation takes 5 minutes

**Realistic cost if you clean up daily:** ~$10-15 for the entire week

## Prerequisites

### Required Knowledge
- ✅ Basic Linux commands (cd, ls, vim, grep, find)
- ✅ Basic shell scripting (variables, loops, functions)
- ✅ SSH and working with remote servers
- ✅ Git basics (clone, commit, push)
- ✅ What Docker containers are (conceptually)

**Test yourself:**
```bash
# If you can do these, you're ready
ls -la
grep "error" /var/log/syslog
ssh user@server
git clone https://github.com/example/repo
docker ps
```

### Required Setup

**AWS Account:**
- AWS Free Tier account (we'll set up on Day 1)
- Credit/debit card (AWS requires this, won't charge if we stay in limits)

**Your Computer:**
- Terminal (Mac/Linux) or WSL (Windows)
- 8GB RAM minimum
- 20GB free disk space
- Stable internet connection

**Tools to Install:**
- AWS CLI
- Git
- Text editor (VS Code recommended)
- SSH client

We'll install Terraform, Ansible, Docker, kubectl as we need them.

## Repository Structure

```
aws-devops-7days/
├── README.md                    # This file
├── day1-foundations/            # Day 1: Manual deployment
│   ├── README.md               # Complete Day 1 guide
│   ├── QUICK-REFERENCE.md      # Quick commands reference
│   ├── manual-steps/           # Step-by-step guides
│   ├── scripts/                # Helper scripts
│   └── diagrams/               # Architecture diagrams
├── day2-terraform/             # Day 2: Terraform IaC
├── day3-ansible/               # Day 3: Ansible configuration
├── day4-jenkins/               # Day 4: CI/CD pipeline
├── day5-kubernetes/            # Day 5: EKS/ECS deployment
├── day6-observability/         # Day 6: Monitoring stack
├── day7-production/            # Day 7: Production hardening
└── common/                     # Shared resources
    ├── cleanup-scripts/
    └── troubleshooting.md
```

## How to Use This Course

### The Recommended Path

1. **Read the day's README completely** before starting
2. **Follow along step-by-step** - don't skip ahead
3. **Type every command yourself** - no copy-paste without understanding
4. **Take notes** on what you learn
5. **Complete the day's project** fully before moving on
6. **Run cleanup scripts** if you want to save money
7. **Document issues** you face for future reference

### Time Commitment

- **Each day:** 7-8 hours (including breaks)
- **Total course:** 50-55 hours of content
- **Can spread:** 2-3 days per section if needed

**My recommendation:** Dedicate focused time blocks. Don't rush. Quality over speed.

## What You'll Have After 7 Days

### Portfolio Projects
1. ✅ Manual AWS deployment of microservices app
2. ✅ Complete Terraform infrastructure codebase
3. ✅ Ansible configuration management automation
4. ✅ Full CI/CD pipeline with Jenkins
5. ✅ Kubernetes/ECS production deployment
6. ✅ Observability stack with custom dashboards
7. ✅ Production-ready, secure, cost-optimized infrastructure

### Skills Mastered
- ✅ AWS services (VPC, EC2, RDS, ALB, EKS/ECS, S3, IAM, CloudWatch)
- ✅ Infrastructure as Code (Terraform)
- ✅ Configuration Management (Ansible)
- ✅ CI/CD (Jenkins)
- ✅ Containers (Docker)
- ✅ Orchestration (Kubernetes/ECS)
- ✅ Monitoring (Prometheus, Grafana, OpenTelemetry)
- ✅ Security (IAM, Security Groups, Secrets Management)
- ✅ Cost Optimization

### Interview Confidence
You'll be able to answer questions like:
- "Explain your AWS networking setup"
- "How do you deploy applications to production?"
- "Walk me through your CI/CD pipeline"
- "How do you monitor and debug production issues?"
- "How do you manage infrastructure as code?"

## Support and Community

### Getting Help

**If you're stuck:**
1. Check the troubleshooting section in each day's README
2. Review the Quick Reference guides
3. Search GitHub Issues (someone probably faced the same issue)
4. Open a new issue with:
   - What you're trying to do
   - What command you ran
   - The exact error message
   - Screenshots if applicable

### Contributing

Found a typo? Have a better way to explain something? Want to add content?

1. Fork the repository
2. Make your changes
3. Submit a Pull Request
4. I review and merge

All contributions are welcome!

### Sharing Your Progress

I'd love to see your progress!
- Tag me on LinkedIn: [Your LinkedIn]
- Use hashtag: #AWSDevOps7Days
- Share your dashboards, architectures, learnings

## About Me

I'm **Koti**, a DevOps Engineer at TransUnion where I manage:
- 1000+ production Kubernetes workloads
- 50+ Kubernetes clusters
- Multi-cloud infrastructure (AWS, Azure, GCP)
- Platform engineering for 200+ developers

**Background:**
- 6+ years in DevOps and Cloud Engineering
- PyCon India 2025 Core Organizer
- Speaker at various tech conferences
- Passionate about sharing practical knowledge

**Why I created this:**
I was frustrated with AWS courses that:
- Focus on certifications, not skills
- Use toy projects, not real infrastructure
- Cost hundreds of dollars
- Leave you unprepared for real work

So I built what I wish existed when I was learning.

## Testimonials

*This section will be updated as people complete the course. Be the first!*

## Frequently Asked Questions

### Do I need AWS certifications first?
No. This course teaches you practical AWS skills. If you want certifications later, this will make studying much easier.

### Can I do this on weekends?
Yes! Each day is self-contained. You can do 1 day per weekend and finish in 7 weeks.

### What if I exceed Free Tier?
Set up billing alerts on Day 1 (we walk through this). Monitor costs daily. Clean up resources when not using them. Realistic total: $10-25.

### Can I use GCP or Azure instead?
No, this course is AWS-specific. The concepts transfer, but commands and services don't.

### Will this prepare me for AWS certifications?
Yes! This covers:
- 70% of AWS Solutions Architect Associate
- 60% of AWS DevOps Engineer Professional
- 50% of AWS SysOps Administrator

But this focuses on practical skills, not exam tricks.

### Can I add this to my resume/portfolio?
Absolutely! You'll have:
- Public GitHub repository with all code
- Working knowledge of production AWS infrastructure
- Real projects you can demo in interviews

## License

MIT License - Use this freely. Learn. Share. Give credit where it's due.

## Acknowledgments

- **WeaveWorks** for the Sock Shop microservices demo application
- **HashiCorp** for Terraform
- **Red Hat** for Ansible
- **AWS** for Free Tier and great documentation
- **Every DevOps engineer** who shared their knowledge openly

## Ready to Start?

Stop reading about DevOps. Start doing DevOps.

👉 **[Begin Day 1: AWS Foundations](./day1-foundations/README.md)**

See you on the other side, where you're an AWS DevOps engineer who actually knows what they're doing.

-Koti

---

**Star this repo** if you find it useful!
**Share it** with someone learning DevOps!
**Follow the journey** - more content coming soon!

[Website](https://devopsengineers.in) | [LinkedIn](your-linkedin) | [Twitter](your-twitter) | [GitHub](your-github)
