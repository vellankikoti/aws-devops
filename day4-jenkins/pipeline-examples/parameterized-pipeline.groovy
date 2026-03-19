// =============================================================================
// Parameterized Pipeline with Approval Gate
// =============================================================================
pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'])
        string(name: 'VERSION', defaultValue: 'latest')
        booleanParam(name: 'DRY_RUN', defaultValue: true)
    }

    stages {
        stage('Validate') {
            steps {
                echo "Environment: ${params.ENV}"
                echo "Version: ${params.VERSION}"
                echo "Dry Run: ${params.DRY_RUN}"
            }
        }

        stage('Approval') {
            when { expression { params.ENV == 'prod' && !params.DRY_RUN } }
            steps {
                input message: "Deploy ${params.VERSION} to PRODUCTION?",
                      ok: "Deploy",
                      submitter: "admin"
            }
        }

        stage('Deploy') {
            when { not { expression { params.DRY_RUN } } }
            steps {
                echo "Deploying version ${params.VERSION} to ${params.ENV}..."
            }
        }
    }
}
