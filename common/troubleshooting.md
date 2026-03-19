# Comprehensive Troubleshooting Guide

## AWS Account Issues

### "Access Denied" Errors
```bash
# Check your identity
aws sts get-caller-identity

# Check permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT:user/USERNAME \
  --action-names ec2:DescribeInstances
```

### Billing Surprises
1. Check AWS Cost Explorer immediately
2. Identify the expensive service
3. Run cleanup scripts: `common/cleanup-scripts/emergency-cleanup.sh`
4. Set up billing alerts (Day 1 guide)

---

## Networking Issues

### Can't SSH to EC2
- Check Security Group allows port 22 from your IP
- Verify key pair matches: `ssh -i key.pem -v ec2-user@IP`
- Check instance is in public subnet with public IP
- Verify route table has 0.0.0.0/0 → Internet Gateway

### Can't Reach Internet from EC2
- Public subnet: Check IGW and route table
- Private subnet: Check NAT Gateway
- Check Security Group outbound rules
- Check NACL rules

### DNS Resolution Failing
- Check VPC has `enableDnsHostnames: true` and `enableDnsSupport: true`

---

## Terraform Issues

### State Lock
```bash
terraform force-unlock LOCK_ID
```

### Provider Errors
```bash
terraform init -upgrade  # Update providers
```

### Dependency Errors
```bash
terraform graph | dot -Tpng > graph.png  # Visualize dependencies
terraform apply -target=module.vpc       # Apply specific module
```

---

## Ansible Issues

### SSH Connection Failures
```bash
ansible all -m ping -vvv  # Verbose debugging
# Check: key permissions (chmod 400), user, host
```

### Privilege Escalation
Add `become: yes` to tasks or `ansible.cfg`

---

## Kubernetes Issues

### Pod Stuck in Pending
```bash
kubectl describe pod POD_NAME -n NAMESPACE
# Usually: insufficient resources, node selector, or PVC issues
```

### CrashLoopBackOff
```bash
kubectl logs POD_NAME -n NAMESPACE --previous  # Check previous container logs
kubectl describe pod POD_NAME -n NAMESPACE      # Check events
```

### OOMKilled
Increase memory limits in deployment manifest.

### ImagePullBackOff
- Check image name/tag exists
- Check ECR authentication: `aws ecr get-login-password | docker login`

---

## Jenkins Issues

### Pipeline Fails
- Check Console Output for exact error
- Verify credentials are configured
- Check plugin versions

### Can't Access Jenkins UI
- Check Security Group port 8080
- Check Jenkins service: `systemctl status jenkins`
- Check logs: `journalctl -u jenkins`

---

## Monitoring Issues

### No Metrics in Prometheus
- Check scrape config targets
- Verify service discovery: Prometheus UI → Status → Targets
- Check network policies

### Grafana Can't Connect to Prometheus
- Verify datasource URL: `http://prometheus:9090`
- Check Prometheus service exists in same namespace

---

## Docker Issues

### Disk Space Full
```bash
docker system prune -a  # Remove unused images, containers, volumes
df -h                    # Check disk usage
```

### Image Pull Failures
```bash
docker pull IMAGE_NAME  # Test manually
# Check Docker Hub rate limits (100 pulls/6hrs for anonymous)
```
