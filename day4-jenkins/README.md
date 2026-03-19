# Day 4: CI/CD Pipeline with Jenkins

**Theme: "Automate the Automation"**

**Time:** 7-8 hours | **Cost:** ~$1.00/day | **Level:** Intermediate-Advanced

---

## My Take: Why CI/CD is the Backbone of DevOps

Here's the thing about Days 1-3: everything we did was manual. You ran `terraform apply`. You ran `ansible-playbook`. You SSHed into servers. What happens when you go on vacation? What happens at 2 AM when there's a critical fix needed?

At TransUnion, we deploy to production multiple times a day. Not because someone clicks a button - because a CI/CD pipeline handles everything. Developer pushes code → pipeline runs tests → infrastructure gets updated → application gets deployed → health checks pass → done. All without human intervention.

That's what we're building today. A Jenkins pipeline that ties together everything from Days 1-3:
1. Terraform creates infrastructure
2. Ansible configures servers
3. Application gets deployed
4. Health checks verify everything works
5. Slack notifies the team

---

## What You'll Build Today

```
┌──────┐     ┌──────────────────────────────────────────────┐
│ Git  │────▶│              Jenkins Pipeline                │
│ Push │     │                                              │
└──────┘     │  ┌─────────┐  ┌─────────┐  ┌────────────┐   │
             │  │Checkout │→│Terraform│→│  Ansible   │   │
             │  │  Code   │  │  Apply  │  │ Configure  │   │
             │  └─────────┘  └─────────┘  └────────────┘   │
             │                                              │
             │  ┌─────────┐  ┌─────────┐  ┌────────────┐   │
             │  │ Deploy  │→│ Health  │→│  Notify   │   │
             │  │  App    │  │ Checks  │  │  Slack    │   │
             │  └─────────┘  └─────────┘  └────────────┘   │
             └──────────────────────────────────────────────┘
```

---

## Morning Session: Jenkins Setup (2 hours)

### Step 1: Install Jenkins on EC2

```bash
# Use our installation script
chmod +x scripts/install-jenkins.sh
./scripts/install-jenkins.sh
```

Or install manually:
```bash
# SSH to your EC2 instance
ssh -i your-key.pem ec2-user@<EC2_IP>

# Install Java 11 (Jenkins requirement)
sudo amazon-linux-extras install java-openjdk11 -y

# Add Jenkins repo
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
sudo yum install jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Step 2: Access Jenkins UI

1. Open `http://<EC2_IP>:8080`
2. Enter the initial admin password
3. Install suggested plugins
4. Create admin user

### Step 3: Install Essential Plugins

Go to Manage Jenkins → Plugins → Available:
- **Pipeline** (usually pre-installed)
- **Git**
- **AWS Steps**
- **Terraform**
- **Ansible**
- **Slack Notification**
- **Blue Ocean** (better pipeline UI)

### Step 4: Configure Credentials

Manage Jenkins → Credentials → System → Global:
- AWS credentials (Access Key + Secret Key)
- GitHub credentials (personal access token)
- SSH key for EC2 access

---

## Afternoon Session: Build the Pipeline (3 hours)

### Understanding Jenkinsfile

The `Jenkinsfile` is your pipeline as code. It lives in your Git repository alongside your application code.

```groovy
// Declarative Pipeline syntax
pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {
        stage('Checkout') { ... }
        stage('Terraform') { ... }
        stage('Ansible') { ... }
        stage('Deploy') { ... }
        stage('Health Check') { ... }
    }

    post {
        success { ... }
        failure { ... }
    }
}
```

### The Complete Pipeline

See the full `Jenkinsfile` in this directory. Key stages:

**Stage 1: Checkout** - Pull latest code from Git
**Stage 2: Terraform Plan** - Preview infrastructure changes
**Stage 3: Approval Gate** - Human approval for production
**Stage 4: Terraform Apply** - Create/update infrastructure
**Stage 5: Ansible Configure** - Configure servers
**Stage 6: Health Check** - Verify application is running
**Stage 7: Notify** - Send results to Slack

### Blue-Green Deployment

The `Jenkinsfile.blue-green` implements blue-green deployment:
1. Deploy new version to "green" environment
2. Run health checks on green
3. Switch ALB to point to green
4. Keep blue as rollback target

> **Production Tip:** At TransUnion, we use canary deployments for critical services. 5% of traffic goes to the new version first. If error rates stay normal for 10 minutes, we roll out to 100%.

---

## Evening Session: Advanced Pipeline Features (2 hours)

### Pipeline Parameters

```groovy
parameters {
    choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'])
    booleanParam(name: 'SKIP_TESTS', defaultValue: false)
    string(name: 'VERSION', defaultValue: 'latest')
}
```

### Rollback Mechanism

```groovy
stage('Rollback') {
    when { expression { params.ROLLBACK } }
    steps {
        sh 'terraform apply -target=module.ec2 -var="app_version=${PREVIOUS_VERSION}"'
    }
}
```

### Shared Libraries

Reusable pipeline code in `shared-library/vars/`:
- `deployApp.groovy` - Standard deployment steps
- `notifySlack.groovy` - Slack notifications

---

## Interactive Exercises

### Challenge 1: Add a Test Stage
Add a stage that runs `curl` against the application and checks for HTTP 200.

### Challenge 2: Parameterize the Pipeline
Add a parameter to choose which environment to deploy to (dev/staging/prod).

### Challenge 3: Add Rollback
Add a manual rollback stage that reverts to the previous Docker image version.

---

## Common Mistakes I Made

1. **Running Jenkins as root** - Always use a dedicated jenkins user
2. **Storing secrets in Jenkinsfile** - Use Jenkins Credentials store
3. **No approval gates for production** - Always require human approval
4. **Ignoring pipeline failures** - Set up notifications immediately
5. **Not versioning Jenkinsfile** - It should be in Git, always

---

## Production Tips

1. **Use Jenkins Configuration as Code (JCasC)** - See `casc/jenkins.yaml`
2. **Run Jenkins in Docker** - See `docker/docker-compose.yml` for easy setup
3. **Back up Jenkins** - `/var/lib/jenkins` is your lifeline
4. **Use shared libraries** - DRY principle applies to pipelines too
5. **Monitor Jenkins itself** - It's infrastructure too!

---

## Deeper Learning Resources

- [Jenkins Pipeline Examples](https://github.com/jenkinsci/pipeline-examples) - Official examples
- [Jenkins Course Repo](https://github.com/wardviaene/jenkins-course) - Comprehensive course
- [Jenkins Configuration as Code](https://github.com/jenkinsci/configuration-as-code-plugin) - JCasC plugin

---

## Cleanup

```bash
chmod +x scripts/cleanup-day4.sh
./scripts/cleanup-day4.sh
```

---

**You now have a fully automated CI/CD pipeline!** Push code → infrastructure builds → app deploys → health checks pass → team gets notified. This is how real DevOps teams work.

-Koti
