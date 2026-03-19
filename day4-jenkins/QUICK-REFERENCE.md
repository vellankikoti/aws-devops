# Day 4: Jenkins Quick Reference

## Jenkins CLI

```bash
# Restart Jenkins
sudo systemctl restart jenkins

# View logs
sudo journalctl -u jenkins -f

# Initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Jenkins home
ls /var/lib/jenkins/
```

## Jenkinsfile Syntax

```groovy
// Declarative Pipeline
pipeline {
    agent any
    parameters { choice(name: 'ENV', choices: ['dev','prod']) }
    environment { MY_VAR = 'value' }
    stages {
        stage('Build') {
            when { branch 'main' }
            steps { sh 'echo building' }
        }
    }
    post {
        success { echo 'done!' }
        failure { echo 'failed!' }
        always { cleanWs() }
    }
}
```

## Common Pipeline Steps

| Step | Description |
|------|-------------|
| `sh 'command'` | Run shell command |
| `checkout scm` | Checkout source code |
| `withCredentials([...])` | Use stored credentials |
| `input 'message'` | Wait for approval |
| `retry(N) { }` | Retry block N times |
| `sleep(N)` | Wait N seconds |
| `error 'msg'` | Fail the build |
| `echo 'msg'` | Print message |
| `cleanWs()` | Clean workspace |

## Credential Types

```groovy
// AWS credentials
withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                  credentialsId: 'aws-creds']]) { }

// SSH key
withCredentials([sshUserPrivateKey(credentialsId: 'ssh-key',
                                    keyFileVariable: 'KEY')]) { }

// Username/password
withCredentials([usernamePassword(credentialsId: 'my-cred',
                                   usernameVariable: 'USER',
                                   passwordVariable: 'PASS')]) { }
```
