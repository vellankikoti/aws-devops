// =============================================================================
// Simple Pipeline - Start Here
// =============================================================================
pipeline {
    agent any

    stages {
        stage('Hello') {
            steps {
                echo 'Hello World! This is my first Jenkins pipeline.'
            }
        }

        stage('Build Info') {
            steps {
                echo "Build Number: ${env.BUILD_NUMBER}"
                echo "Job Name: ${env.JOB_NAME}"
                sh 'whoami'
                sh 'pwd'
            }
        }

        stage('AWS Check') {
            steps {
                sh 'aws sts get-caller-identity || echo "AWS not configured"'
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished!'
        }
    }
}
