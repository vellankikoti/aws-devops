// Shared Library: Standard deployment steps
def call(Map config = [:]) {
    def environment = config.environment ?: 'dev'
    def version = config.version ?: 'latest'

    echo "Deploying version ${version} to ${environment}"

    stage('Infrastructure') {
        dir("day2-terraform/environments/${environment}") {
            sh 'terraform init -no-color'
            sh 'terraform apply -no-color -auto-approve'
        }
    }

    stage('Configure') {
        dir('day3-ansible') {
            sh "ansible-playbook -i inventory/aws_ec2.yml playbooks/site.yml"
        }
    }

    stage('Verify') {
        retry(5) {
            sleep(10)
            sh "curl -sf http://localhost:8079/ > /dev/null"
        }
        echo "Deployment verified successfully!"
    }
}
