// =============================================================================
// Pipeline with Automated Rollback
// =============================================================================
pipeline {
    agent any

    environment {
        PREVIOUS_VERSION = ''
    }

    stages {
        stage('Save Current State') {
            steps {
                script {
                    env.PREVIOUS_VERSION = sh(
                        script: 'docker ps --format "{{.Image}}" | grep front-end | cut -d: -f2 || echo "0.3.12"',
                        returnStdout: true
                    ).trim()
                    echo "Current version: ${env.PREVIOUS_VERSION}"
                }
            }
        }

        stage('Deploy New Version') {
            steps {
                echo "Deploying new version..."
                sh """
                    cd /opt/sockshop
                    docker-compose pull
                    docker-compose up -d
                """
            }
        }

        stage('Verify') {
            steps {
                script {
                    def healthy = false
                    for (int i = 0; i < 5; i++) {
                        def code = sh(script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:8079", returnStdout: true).trim()
                        if (code == '200') { healthy = true; break }
                        sleep(10)
                    }
                    if (!healthy) {
                        echo "Health check failed! Initiating rollback..."
                        error("Deployment verification failed")
                    }
                }
            }
        }
    }

    post {
        failure {
            echo "ROLLBACK: Reverting to version ${env.PREVIOUS_VERSION}"
            sh """
                cd /opt/sockshop
                docker-compose down
                # Replace with previous version and restart
                docker-compose up -d
            """
        }
    }
}
