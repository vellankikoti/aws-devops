# Day 3: Configuration Management with Ansible

**Theme: "Configure at Scale"**

**Time:** 7-8 hours | **Cost:** ~$0.50/day | **Level:** Intermediate

---

## My Take: Why Configuration Management Saved My Sanity

Let me tell you about the worst Friday of my career. We had 47 servers that needed a critical security patch. I SSH'd into each one manually, ran the update, restarted the service, and verified it was working. It took me 14 hours. And I missed one server. That one unpatched server got compromised over the weekend.

That Monday, my tech lead introduced me to Ansible. "Never log into a server manually again," he said. It changed everything.

**Terraform creates your infrastructure. Ansible configures it.** Think of it this way:
- Terraform builds the house (walls, plumbing, electricity)
- Ansible furnishes it (installs software, configures services, manages files)

Today, we'll automate everything we manually configured on Day 1 - Docker installation, Sock Shop deployment, monitoring setup - all with Ansible.

---

## What You'll Build Today

```
┌──────────────────────────────────────────────────────┐
│                  Ansible Control Node                │
│                  (Your Laptop)                       │
│  ┌─────────┐  ┌──────────┐  ┌───────────────────┐   │
│  │Playbooks│  │Inventory │  │  Ansible Vault    │   │
│  │         │  │(Dynamic) │  │  (Secrets)        │   │
│  └────┬────┘  └────┬─────┘  └────────┬──────────┘   │
└───────┼─────────────┼────────────────┼───────────────┘
        │             │                │
        ▼             ▼                ▼
   ┌─────────────────────────────────────┐
   │          SSH (Port 22)              │
   └──────┬──────────────┬──────────────┘
          │              │
   ┌──────▼─────┐  ┌────▼───────┐
   │  EC2 App   │  │  EC2 App   │
   │  Server 1  │  │  Server 2  │
   │ ┌────────┐ │  │ ┌────────┐ │
   │ │Docker  │ │  │ │Docker  │ │
   │ │SockShop│ │  │ │SockShop│ │
   │ │Monitor │ │  │ │Monitor │ │
   │ └────────┘ │  │ └────────┘ │
   └────────────┘  └────────────┘
```

---

## Prerequisites

- ✅ Day 1 & Day 2 completed
- ✅ At least one EC2 instance running (from Day 2 Terraform)
- ✅ SSH key pair to access EC2 instances
- ✅ Python 3 installed on your machine

---

## Morning Session: Ansible Fundamentals (2 hours)

### Step 1: Install Ansible

```bash
# Python pip (recommended)
pip3 install ansible boto3 botocore

# Verify
ansible --version
# ansible [core 2.15.x]
```

### Step 2: Understand Ansible Concepts

**Key Concepts:**
- **Inventory**: List of servers to manage
- **Playbook**: YAML file describing desired state
- **Role**: Reusable collection of tasks
- **Module**: Unit of work (apt, yum, copy, service, etc.)
- **Handler**: Task triggered by notifications
- **Vault**: Encrypted secrets storage

> **The #1 Rule of Ansible: Idempotency.** Run a playbook once or 100 times - the result is the same. If Docker is already installed, Ansible won't reinstall it. If a file already has the right content, Ansible won't rewrite it. This is what makes Ansible safe to run repeatedly.

### Step 3: Configure Ansible

Look at our `ansible.cfg`:
```ini
[defaults]
inventory = ./inventory/hosts
remote_user = ec2-user
private_key_file = ~/.ssh/your-key.pem
host_key_checking = False
retry_files_enabled = False
roles_path = ./roles

[privilege_escalation]
become = True
become_method = sudo
```

### Step 4: Set Up Inventory

**Static inventory** (`inventory/hosts`):
```ini
[webservers]
web1 ansible_host=<EC2_PUBLIC_IP>

[databases]
# RDS is managed by AWS, no Ansible needed

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/your-key.pem
```

**Dynamic inventory** (`inventory/aws_ec2.yml`):
```yaml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  tag:Project: SockShop
  instance-state-name: running
keyed_groups:
  - key: tags.Role
    prefix: role
```

```bash
# Test connectivity
ansible all -m ping
# web1 | SUCCESS => {"ping": "pong"}
```

> **Interactive Exercise:** Try running `ansible all -m setup` to see ALL facts Ansible knows about your servers. It's like `uname -a` on steroids!

---

## Afternoon Session: Building Playbooks (3 hours)

### Playbook 1: Install Docker

```bash
# Run it
ansible-playbook playbooks/setup-docker.yml
```

This playbook:
1. Updates the system
2. Installs Docker and Docker Compose
3. Starts Docker service
4. Adds ec2-user to docker group

### Playbook 2: Deploy Sock Shop

```bash
ansible-playbook playbooks/deploy-sockshop.yml
```

This playbook uses a Jinja2 template for docker-compose.yml, allowing us to customize the deployment per environment.

### Playbook 3: Configure Monitoring

```bash
ansible-playbook playbooks/configure-monitoring.yml
```

Sets up CloudWatch agent for log forwarding and basic metrics.

### Master Playbook: Run Everything

```bash
# Deploy everything in one command
ansible-playbook playbooks/site.yml
```

### Understanding Roles

Roles organize playbooks into reusable components:
```
roles/
├── docker/           # Docker installation
│   ├── tasks/main.yml
│   ├── handlers/main.yml
│   └── defaults/main.yml
├── sockshop/         # App deployment
│   ├── tasks/main.yml
│   ├── templates/docker-compose.yml.j2
│   ├── handlers/main.yml
│   └── defaults/main.yml
├── monitoring/       # CloudWatch setup
│   ├── tasks/main.yml
│   ├── templates/cloudwatch-config.json.j2
│   └── defaults/main.yml
└── security/         # Security hardening
    └── tasks/main.yml
```

---

## Evening Session: Advanced Ansible (2 hours)

### Ansible Vault - Secrets Management

```bash
# Create encrypted file
ansible-vault create group_vars/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/vault.yml

# Run playbook with vault
ansible-playbook site.yml --ask-vault-pass

# Or use password file
ansible-playbook site.yml --vault-password-file ~/.vault_pass
```

### Handlers - React to Changes

```yaml
tasks:
  - name: Update nginx config
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify: restart nginx

handlers:
  - name: restart nginx
    service:
      name: nginx
      state: restarted
```

> Handlers only run if a task reports "changed". If the config file hasn't changed, nginx won't restart. This is smart automation!

### Error Handling

```yaml
- name: Deploy with error handling
  block:
    - name: Deploy application
      docker_compose:
        project_src: /opt/sockshop
        state: present
  rescue:
    - name: Rollback on failure
      docker_compose:
        project_src: /opt/sockshop-backup
        state: present
  always:
    - name: Send notification
      debug:
        msg: "Deployment attempt completed"
```

---

## Interactive Exercises

### Challenge 1: Add a New Role
Create a role called `nginx` that installs and configures Nginx as a reverse proxy in front of Sock Shop.

### Challenge 2: Dynamic Inventory
Modify the AWS EC2 dynamic inventory to group instances by their `Environment` tag.

### Challenge 3: Break and Fix
1. Change the Docker Compose template to use a non-existent image
2. Run the playbook - watch it fail
3. Fix it and re-run - observe idempotency

---

## Common Mistakes I Made (So You Don't Have To)

1. **Forgetting `become: yes`** - Most tasks need root/sudo
2. **Not using handlers** - Restarting services in tasks means unnecessary restarts
3. **Hardcoding IPs** - Use dynamic inventory or variables
4. **Not testing with `--check`** - Dry run before applying!
5. **Ignoring return codes** - Use `register` and `failed_when`

---

## Production Tips from the Trenches

1. **Always use `--diff`** to see what changed
2. **Use `--limit` to target specific servers** before rolling out everywhere
3. **Keep playbooks idempotent** - test by running twice
4. **Use tags** to run specific parts: `ansible-playbook site.yml --tags docker`
5. **Store vault password in CI/CD** - never in git

---

## Deeper Learning Resources

- [Ansible Examples](https://github.com/ansible/ansible-examples) - Official examples
- [Ansible for DevOps](https://github.com/geerlingguy/ansible-for-devops) - Jeff Geerling's excellent book/repo
- [Ansible Galaxy](https://galaxy.ansible.com/) - Community roles

---

## What's Next?

Tomorrow (Day 4), we'll build a **CI/CD pipeline with Jenkins** that ties Terraform and Ansible together:
1. Jenkins detects code change
2. Runs `terraform apply` to create infrastructure
3. Runs `ansible-playbook` to configure servers
4. Runs health checks to verify deployment

Fully automated, end to end!

---

## Cleanup

```bash
chmod +x scripts/cleanup-day3.sh
./scripts/cleanup-day3.sh
```

-Koti
