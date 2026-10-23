pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Project') {
            steps {
                echo 'GitHub push triggered the Jenkins pipeline!'
                sh 'pwd'
                sh 'ls -la'
                sh 'test -f Dockerfile'
                sh 'test -f build/index.html'
            }
        }
    }
}
