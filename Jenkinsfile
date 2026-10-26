pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
    }

    triggers {
        pollSCM('H/2 * * * *')
    }

    tools {
        maven 'Maven3'
    }

    stages {
        stage('1. Checkout') {
            steps {
                checkout scm
            }
        }

        stage('2. Build Application') {
            steps {
                bat 'node --version'
                bat 'node --check server.js'
                bat 'mvn -B -DskipTests clean package'
            }
        }

        stage('3. Deploy to QA Environment') {
            steps {
                bat 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File ci\\StartApi.ps1'
            }
        }

        stage('4. Notify QA - Deployment Ready') {
            steps {
                echo 'DEPLOYMENT SUCCESS: Demo API is ready at http://127.0.0.1:3000'
                echo 'QA notification: Starting Rest Assured smoke tests.'
            }
        }

        stage('5. Run API Smoke Test') {
            steps {
                bat 'mvn -B test "-Dtest=simpleTest"'
            }
        }
    }

    post {
        always {
            bat 'if exist ci\\StopApi.ps1 powershell.exe -NoProfile -ExecutionPolicy Bypass -File ci\\StopApi.ps1'

            junit allowEmptyResults: true,
                  testResults: 'target/surefire-reports/*.xml'

            archiveArtifacts allowEmptyArchive: true,
                artifacts: 'target/surefire-reports/*.xml,target/ci-api-server.log,target/ci-api-server-error.log'
        }

        success {
            echo 'SUCCESS: Deployment and API smoke test passed.'
        }

        failure {
            echo 'FAILURE: Check Console Output and the test reports.'
        }
    }
}