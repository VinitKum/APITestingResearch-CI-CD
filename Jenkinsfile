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
                bat 'curl.exe --fail --silent --show-error --output NUL --max-time 5 http://127.0.0.1:3000/users'
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
        }

        failure {
            echo 'FAILURE: Check Console Output and test reports.'
        }
    }
}