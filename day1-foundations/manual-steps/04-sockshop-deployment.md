# Sock Shop Deployment - Detailed Guide

## What We're Deploying

Sock Shop is a microservices demo application by Weaveworks that simulates an e-commerce site selling socks. It consists of 13-14 containers:

| Service | Technology | Port | Purpose |
|---------|-----------|------|---------|
| front-end | Node.js | 8079 | Web UI |
| catalogue | Go | 80 | Product catalog |
| catalogue-db | MySQL | 3306 | Product data |
| carts | Java | 80 | Shopping cart |
| carts-db | MongoDB | 27017 | Cart data |
| orders | Java | 80 | Order processing |
| orders-db | MongoDB | 27017 | Order data |
| payment | Go | 80 | Payment processing |
| shipping | Java | 80 | Shipping calculation |
| user | Go | 80 | User management |
| user-db | MongoDB | 27017 | User data |
| queue-master | Java | 80 | Message queue worker |
| rabbitmq | RabbitMQ | 5672 | Message broker |
| edge-router | Traefik | 80 | API gateway |

This is a realistic microservices architecture - similar to what you'd find in production.

## Prerequisites

- [ ] EC2 instance running with Docker and Docker Compose ([03-ec2-setup.md](./03-ec2-setup.md))
- [ ] SSH access to the instance confirmed
- [ ] Docker working: `docker ps` returns no errors

## Step 1: SSH into Your Instance

```bash
# Ubuntu
ssh -i ~/.ssh/sockshop-key.pem ubuntu@YOUR_PUBLIC_IP

# Amazon Linux
ssh -i ~/.ssh/sockshop-key.pem ec2-user@YOUR_PUBLIC_IP
```

## Step 2: Clone the Sock Shop Repository

```bash
# Navigate to home directory
cd ~

# Clone the microservices-demo repository
git clone https://github.com/microservices-demo/microservices-demo.git

# Navigate to Docker Compose directory
cd microservices-demo/deploy/docker-compose

# Verify the docker-compose file exists
ls -la docker-compose.yml
```

## Step 3: Review What We're Deploying

Before deploying, always review what you're running:

```bash
# See the full compose file
cat docker-compose.yml

# Count the number of services
grep -c "image:" docker-compose.yml
```

Take a few minutes to read the file. Notice:
- Each service uses a specific Docker image
- Services communicate via Docker networking
- Databases store data in Docker volumes
- The front-end exposes port 8079

## Step 4: Deploy Sock Shop

```bash
# Pull all images first (so you can see progress)
docker-compose pull

# Start all services in detached mode
docker-compose up -d
```

**This takes 5-10 minutes** on first run as Docker downloads all the images.

### Monitor Progress

```bash
# Watch container startup (Ctrl+C to stop watching)
docker-compose logs -f

# In a separate terminal, check container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Wait for All Containers

```bash
# Quick check: count running containers
docker ps --format '{{.Names}}' | wc -l
# Should show 13-14

# Check for any containers that aren't running
docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Status}}"
```

## Step 5: Verify the Deployment

### Check All Services are Healthy

```bash
# List all containers with their health
docker-compose ps

# Check specific service logs if something is down
docker-compose logs catalogue
docker-compose logs front-end
docker-compose logs orders
```

### Test the Frontend

```bash
# Test from the instance itself
curl -s http://localhost:8079 | head -20

# You should see HTML starting with <!DOCTYPE html>
# If you see HTML, the frontend is working!
```

### Test Individual Services

```bash
# Test catalogue service (product listing)
curl -s http://localhost:8079/catalogue | python3 -m json.tool | head -20

# Test user service
curl -s http://localhost:8079/customers | head -5

# Test cart service
curl -s http://localhost:8079/cart | head -5
```

### Test from Your Browser

Open in your browser:
```
http://YOUR_EC2_PUBLIC_IP:8079
```

You should see the Sock Shop homepage with socks for sale.

**If it doesn't load:**
1. Check security group allows port 8079 from your IP
2. Check the front-end container is running: `docker ps | grep front-end`
3. Check front-end logs: `docker-compose logs front-end`

## Step 6: Explore the Application

Take 10 minutes to explore - this helps you understand the microservices architecture:

1. **Browse Products**: Click on socks, view details
   - This exercises: front-end → catalogue → catalogue-db
2. **Register an Account**: Click Login → Register
   - This exercises: front-end → user → user-db
3. **Add to Cart**: Click "Add to cart" on any product
   - This exercises: front-end → carts → carts-db
4. **Place an Order**: Go to cart → Proceed to checkout
   - This exercises: front-end → orders → payment → shipping → orders-db + queue-master + rabbitmq

Each action involves multiple microservices communicating. In production, this is exactly how modern applications work.

## Step 7: Understand the Architecture

```
Browser → front-end (Node.js, port 8079)
              ├── catalogue (Go) → catalogue-db (MySQL)
              ├── carts (Java) → carts-db (MongoDB)
              ├── orders (Java) → orders-db (MongoDB)
              │       ├── payment (Go)
              │       └── shipping (Java)
              ├── user (Go) → user-db (MongoDB)
              └── queue-master (Java) → rabbitmq (RabbitMQ)
```

**Key observations:**
- Each service has its own database (database-per-service pattern)
- Services communicate via HTTP REST APIs
- RabbitMQ handles async messaging (order processing)
- Front-end aggregates data from multiple services

## Step 8: Resource Usage Check

```bash
# Check how much memory Docker is using
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Check disk usage
df -h /
docker system df
```

**Note:** t2.micro has 1 GB RAM. Sock Shop uses ~800-900MB. It's tight but works for learning. In production, you'd use larger instances.

## Troubleshooting

### Container keeps restarting

```bash
# Check which container is failing
docker ps -a --filter "status=restarting"

# Check its logs
docker logs <container-name> --tail 50

# Common fix: restart all services
docker-compose down
docker-compose up -d
```

### "Cannot connect to the Docker daemon"

```bash
# Make sure Docker is running
sudo systemctl start docker

# Check if you need group permissions
groups
# If 'docker' not listed, log out and back in
exit
# SSH back in
```

### Out of disk space

```bash
# Check disk
df -h /

# Clean up unused Docker resources
docker system prune -a --volumes
# WARNING: This removes all stopped containers and unused images
```

### Port 8079 not accessible from browser

1. Check container is running: `docker ps | grep front-end`
2. Check security group allows port 8079
3. Test locally first: `curl localhost:8079`
4. If local works but browser doesn't: it's a networking/security group issue

## Useful Docker Commands for This Project

```bash
# View all running containers
docker-compose ps

# View logs for all services
docker-compose logs

# View logs for specific service
docker-compose logs -f front-end

# Restart a specific service
docker-compose restart catalogue

# Stop everything
docker-compose down

# Start everything
docker-compose up -d

# Stop and remove all data (fresh start)
docker-compose down -v
```

## What You Learned

- How Docker Compose orchestrates multi-container applications
- Microservices architecture patterns (database-per-service, API gateway)
- How modern applications are structured (frontend, backend services, databases, message queues)
- Basic Docker troubleshooting

## Next Step

Sock Shop is running on Docker's embedded databases. Let's add a production-grade managed database.

**Next**: [05-rds-setup.md](./05-rds-setup.md) - Set up RDS MySQL for production data

---

**Time spent**: ~20-30 minutes (including image download time)
**Cost so far**: $0 (still on EC2 Free Tier)
**Containers running**: 13-14 microservices
