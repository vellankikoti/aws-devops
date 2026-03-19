# Day 5: Container Orchestration with ECS/EKS

**Theme: "Kubernetes in the Cloud"**

**Time:** 7-8 hours | **Cost:** ~$3.50/day (EKS) OR $0 (ECS Fargate) | **Level:** Advanced

---

## My Take: Managing 1000+ K8s Workloads Taught Me This

I manage 1000+ Kubernetes workloads across 50+ clusters at TransUnion. Here's what I wish someone told me on Day 1: **Kubernetes is not a goal, it's a tool.** Don't use K8s because it's cool. Use it because you need container orchestration at scale.

For our Sock Shop with 14 containers, Docker Compose on a single EC2 instance works fine. But what happens when:
- Your app needs to handle 10x traffic?
- A container crashes at 3 AM?
- You need zero-downtime deployments?
- You need to run across multiple availability zones?

That's when you need orchestration. Today, we provide TWO paths:

### Path A: ECS Fargate (RECOMMENDED - FREE)
- Uses AWS Free Tier
- Serverless containers - no EC2 to manage
- Great for learning container orchestration concepts
- **Cost: $0**

### Path B: EKS (ADVANCED - PAID)
- Real Kubernetes cluster
- Industry standard
- More complex but more powerful
- **Cost: ~$3.50/day** ($0.10/hr for control plane)

> **My recommendation:** Start with ECS Fargate to learn concepts for free. Then try EKS if you want real K8s experience and are willing to pay.

---

## What You'll Build Today

```
┌────────────────────────────────────────────────────┐
│                EKS/ECS Cluster                     │
│  ┌──────────────────────────────────────────────┐  │
│  │            Namespace: sock-shop               │  │
│  │                                               │  │
│  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────────┐    │  │
│  │  │front │ │carts │ │orders│ │catalogue │    │  │
│  │  │-end  │ │      │ │      │ │          │    │  │
│  │  │ x2   │ │ x1   │ │ x1   │ │   x1     │    │  │
│  │  └──────┘ └──────┘ └──────┘ └──────────┘    │  │
│  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────────┐    │  │
│  │  │user  │ │pay-  │ │ship- │ │queue-    │    │  │
│  │  │      │ │ment  │ │ping  │ │master    │    │  │
│  │  └──────┘ └──────┘ └──────┘ └──────────┘    │  │
│  │                                               │  │
│  │  ┌────────────┐  ┌───────────────────┐       │  │
│  │  │   HPA      │  │ Cluster Autoscaler│       │  │
│  │  │(auto-scale)│  │  (node scaling)   │       │  │
│  │  └────────────┘  └───────────────────┘       │  │
│  └──────────────────────────────────────────────┘  │
│                                                    │
│  ┌──────────┐  ┌───────────┐                       │
│  │ALB Ingress│  │ Metrics   │                       │
│  │Controller │  │ Server    │                       │
│  └──────────┘  └───────────┘                       │
└────────────────────────────────────────────────────┘
```

---

## Prerequisites

- ✅ Days 1-4 completed
- ✅ kubectl installed
- ✅ eksctl installed (for EKS path)
- ✅ AWS CLI configured

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Install eksctl (for EKS path)
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin/
```

---

## Morning Session: Cluster Setup (2 hours)

### Path A: ECS Fargate (Free)

```bash
chmod +x ecs-fargate/ecs-cluster.sh
./ecs-fargate/ecs-cluster.sh
```

### Path B: EKS Cluster

```bash
chmod +x scripts/create-eks-cluster.sh
./scripts/create-eks-cluster.sh

# This takes ~15 minutes. Creates:
# - EKS control plane
# - 2 worker nodes (t3.medium)
# - VPC and networking
```

### Kubernetes Basics Crash Course

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes

# Namespaces (like folders for resources)
kubectl get namespaces
kubectl create namespace sock-shop
```

> **Memory Technique:** Think of Kubernetes like a restaurant:
> - **Cluster** = The restaurant
> - **Nodes** = Kitchen stations
> - **Pods** = Individual dishes being prepared
> - **Deployments** = The menu (defines what dishes to make)
> - **Services** = The waiters (route customers to dishes)
> - **Ingress** = The front door (routes external traffic)

---

## Afternoon Session: Deploy Sock Shop (3 hours)

### Step 1: Create Namespace

```bash
kubectl apply -f manifests/namespace.yaml
```

### Step 2: Deploy All Services

```bash
# Deploy everything at once
chmod +x scripts/deploy-sockshop.sh
./scripts/deploy-sockshop.sh

# Or deploy individually
kubectl apply -f manifests/deployments/ -n sock-shop
kubectl apply -f manifests/services/ -n sock-shop
kubectl apply -f manifests/configmaps/ -n sock-shop
```

### Step 3: Check Status

```bash
# Watch pods come up
kubectl get pods -n sock-shop -w

# Check all resources
kubectl get all -n sock-shop

# Check logs if a pod is failing
kubectl logs -n sock-shop <pod-name>

# Describe a pod for troubleshooting
kubectl describe pod -n sock-shop <pod-name>
```

### Step 4: Expose with Ingress

```bash
kubectl apply -f manifests/ingress.yaml
kubectl get ingress -n sock-shop
```

---

## Evening Session: Advanced K8s (2 hours)

### Horizontal Pod Autoscaling

```bash
kubectl apply -f autoscaling/hpa.yaml
kubectl apply -f autoscaling/metrics-server.yaml

# Watch scaling in action
kubectl get hpa -n sock-shop -w
```

### Generate Load to Test Autoscaling

```bash
# In a separate terminal
kubectl run load-gen --image=busybox -- /bin/sh -c \
  "while true; do wget -q -O- http://front-end.sock-shop; done"

# Watch HPA scale up
kubectl get hpa -n sock-shop -w
```

---

## Interactive Exercises

### Challenge 1: Scale Manually
```bash
kubectl scale deployment front-end -n sock-shop --replicas=5
# Watch pods come up, then scale back to 2
```

### Challenge 2: Kill a Pod
```bash
kubectl delete pod <front-end-pod> -n sock-shop
# Watch Kubernetes automatically recreate it!
```

### Challenge 3: Rolling Update
Change the front-end image version and watch the rolling update happen with zero downtime.

---

## Common Mistakes I Made

1. **Not setting resource limits** - Pods consume all node resources
2. **Using latest tag** - Can't rollback if you don't know the version
3. **Not setting up HPA** - Manual scaling doesn't scale
4. **Ignoring pod disruption budgets** - Updates can cause downtime
5. **Not using namespaces** - Everything in default namespace is chaos

---

## Deeper Learning Resources

- [Sock Shop K8s Manifests](https://github.com/microservices-demo/microservices-demo/tree/master/deploy/kubernetes) - Official manifests
- [Kubernetes Examples](https://github.com/kubernetes/examples) - Official examples
- [EKS Best Practices](https://github.com/aws/eks-charts) - AWS EKS add-ons
- [EKS Masterclass](https://github.com/stacksimplify/aws-eks-kubernetes-masterclass) - Comprehensive EKS course

---

## Cleanup

```bash
chmod +x scripts/cleanup-day5.sh
./scripts/cleanup-day5.sh
```

> **IMPORTANT:** EKS costs $0.10/hour ($2.40/day). Delete the cluster when done!

---

**Congratulations!** You now understand container orchestration on AWS. Whether you chose ECS Fargate or EKS, you've deployed a microservices application with auto-scaling, health checks, and production-grade configuration.

-Koti
