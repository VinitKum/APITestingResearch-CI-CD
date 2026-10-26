// Verify automatic SCM polling trigger
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
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

        stage('2. Build') {
            steps {
                bat 'mvn -B -DskipTests clean package'
            }
        }

      stage('3. Verify QA API') {
          steps {
              bat '"%SystemRoot%\\System32\\curl.exe" --fail --silent --show-error --output NUL --max-time 5 http://127.0.0.1:3000/users'
              echo 'QA API is reachable.'
          }
      }

        stage('4. API Smoke Test') {
            steps {
                bat 'mvn -B test "-Dtest=simpleTest"'
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true,
                  testResults: 'target/surefire-reports/*.xml'
        }

        success {
            echo 'SUCCESS: Build and API smoke test passed.'

            script {
                try {
                    slackSend(
                        channel: '#all-jenkins-ci-notifications',
                        color: 'good',
                        tokenCredentialId: 'slack-bot-token',
                        botUser: true,
                        message: "✅ BUILD SUCCESS\nJob: ${env.JOB_NAME}\nBuild: #${env.BUILD_NUMBER}\n<${env.BUILD_URL}|Open Jenkins build>"
                    )
                } catch (err) {
                    echo "Slack notification failed: ${err.message}"
                }
            }
        }

        failure {
            echo 'FAILURE: Check Console Output and test reports.'

            script {
                try {
                    slackSend(
                        channel: '#all-jenkins-ci-notifications',
                        color: 'danger',
                        tokenCredentialId: 'slack-bot-token',
                        botUser: true,
                        message: "❌ BUILD FAILED\nJob: ${env.JOB_NAME}\nBuild: #${env.BUILD_NUMBER}\n<${env.BUILD_URL}console|Open Console Output>"
                    )
                } catch (err) {
                    echo "Slack notification failed: ${err.message}"
                }
            }
        }
    }
}