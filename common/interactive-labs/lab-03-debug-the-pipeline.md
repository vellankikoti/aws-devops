# Lab 03: Debug the Broken Pipeline

## Scenario
Your Jenkins pipeline is failing. Here's the Jenkinsfile with 5 bugs:

```groovy
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/nonexistent/repo'  // Bug 1: Wrong repo URL
            }
        }
        stage('Build') {
            steps {
                sh 'terraform appy'  // Bug 2: Typo in command
            }
        }
        stage('Deploy') {
            steps {
                sh 'ansible-playbook site.yml'  // Bug 3: Missing inventory
            }
        }
        stage('Test') {
            steps {
                sh 'curl http://localhost:8080'  // Bug 4: Wrong port
            }
        }
    }
    // Bug 5: No post section for failure handling
}
```

## Tasks
1. Identify all 5 bugs
2. Fix each bug
3. Add proper error handling
4. Add a notification stage
