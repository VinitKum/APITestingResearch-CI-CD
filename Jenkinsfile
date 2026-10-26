pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    tools {
        maven 'Maven3'
    }

    triggers {
        pollSCM('H/2 * * * *')
    }

    stages {
        stage('1. Checkout') {
            steps {
                checkout scm
            }
        }

        stage('2. Build Automation Framework') {
            steps {
                bat 'mvn -B -DskipTests clean package'
            }
        }

        stage('3. Deploy QA Application') {
            steps {
                bat '"%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "CI\\DeployQaApi.ps1"'
            }
            post {
                success {
                    script {
                        try {
                            slackSend(
                                channel: '#all-jenkins-ci-notifications',
                                color: 'good',
                                tokenCredentialId: 'slack-bot-token',
                                botUser: true,
                                message: "🚀 DEPLOYMENT SUCCESS\nJob: ${env.JOB_NAME}\nBuild: #${env.BUILD_NUMBER}\nQA URL: http://127.0.0.1:3001\n<${env.BUILD_URL}|Open Jenkins build>"
                            )
                        } catch (err) {
                            echo "Deployment Slack notification failed: ${err.message}"
                        }
                    }
                }
            }
        }

        stage('4. Verify Deployed QA Application') {
            steps {
                bat '"%SystemRoot%\\System32\\curl.exe" --fail --silent --show-error --output NUL --max-time 5 http://127.0.0.1:3001/health'
                echo 'QA deployment health check passed.'
            }
        }

        stage('5. API Smoke Test') {
            steps {
                bat 'mvn -B test "-Dtest=simpleTest" "-DbaseUrl=http://127.0.0.1:3001"'
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true,
                  testResults: 'target/surefire-reports/*.xml'
        }

        success {
            script {
                try {
                    slackSend(
                        channel: '#all-jenkins-ci-notifications',
                        color: 'good',
                        tokenCredentialId: 'slack-bot-token',
                        botUser: true,
                        message: "✅ CI/CD SUCCESS\nJob: ${env.JOB_NAME}\nBuild: #${env.BUILD_NUMBER}\nQA deployment and API smoke test passed.\n<${env.BUILD_URL}|Open Jenkins build>"
                    )
                } catch (err) {
                    echo "Final Slack notification failed: ${err.message}"
                }
            }
        }

        failure {
            script {
                try {
                    slackSend(
                        channel: '#all-jenkins-ci-notifications',
                        color: 'danger',
                        tokenCredentialId: 'slack-bot-token',
                        botUser: true,
                        message: "❌ CI/CD FAILED\nJob: ${env.JOB_NAME}\nBuild: #${env.BUILD_NUMBER}\nCheck deployment logs, Console Output and JUnit reports.\n<${env.BUILD_URL}console|Open Console Output>"
                    )
                } catch (err) {
                    echo "Failure Slack notification failed: ${err.message}"
                }
            }
        }
    }
}
