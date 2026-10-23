
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'shanmugapriya2390/dev'
        APP_HOST = '172.31.15.240'
        APP_USER = 'ubuntu'
        CONTAINER_NAME = 'devops-build-app'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Project') {
            steps {
                sh '''
                    set -e
                    test -f Dockerfile
                    test -f build/index.html
                    echo "Project files verified."
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -e
                    docker build \
                      -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                      -t ${IMAGE_NAME}:latest \
                      .
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        set -eu
                        set +x
                        echo "$DOCKERHUB_TOKEN" | docker login \
                          --username "$DOCKERHUB_USERNAME" \
                          --password-stdin

                        docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                        docker push ${IMAGE_NAME}:latest
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to App EC2') {
            steps {
                sshagent(credentials: ['app-server-ssh-key']) {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'dockerhub-credentials',
                            usernameVariable: 'DOCKERHUB_USERNAME',
                            passwordVariable: 'DOCKERHUB_TOKEN'
                        )
                    ]) {
                        sh '''
                            set -eu
                            set +x

                            printf '%s' "$DOCKERHUB_TOKEN" | \
                              ssh -o StrictHostKeyChecking=accept-new \
                              ${APP_USER}@${APP_HOST} \
                              "docker login --username '$DOCKERHUB_USERNAME' --password-stdin"

                            ssh -o StrictHostKeyChecking=accept-new \
                              ${APP_USER}@${APP_HOST} \
                              "sudo docker pull ${IMAGE_NAME}:${BUILD_NUMBER} &&
                               sudo docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
                               sudo docker run -d --name ${CONTAINER_NAME} \
                                 --restart unless-stopped -p 80:80 \
                                 ${IMAGE_NAME}:${BUILD_NUMBER}"

                            ssh -o StrictHostKeyChecking=accept-new \
                              ${APP_USER}@${APP_HOST} \
                              "sudo docker image prune -f"

                            ssh -o StrictHostKeyChecking=accept-new \
                              ${APP_USER}@${APP_HOST} \
                              "curl -fsS http://localhost/ >/dev/null"
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Development image built, pushed, and deployed successfully.'
        }
        failure {
            echo 'Pipeline failed. Check Console Output for the failing stage.'
        }
    }
}
