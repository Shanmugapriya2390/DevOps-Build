pipeline {
    agent any

    environment {
        DOCKERHUB_NAMESPACE = 'shanmugapriya2390'
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

        stage('Select Image') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'master') {
                        env.IMAGE_NAME = "${DOCKERHUB_NAMESPACE}/prod"
                    } else if (env.BRANCH_NAME == 'dev') {
                        env.IMAGE_NAME = "${DOCKERHUB_NAMESPACE}/dev"
                    } else {
                        error("Unsupported branch: ${env.BRANCH_NAME}")
                    }

                    env.IMAGE_TAG = env.BUILD_NUMBER
                    echo "Branch: ${env.BRANCH_NAME}"
                    echo "Image: ${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                }
            }
        }

        stage('Verify Project') {
            steps {
                sh '''
                    set -eu
                    test -f Dockerfile
                    test -f build/index.html
                    echo "Project files verified."
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eu
                    docker build \
                      -t "$IMAGE_NAME:$IMAGE_TAG" \
                      -t "$IMAGE_NAME:latest" \
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

                        docker push "$IMAGE_NAME:$IMAGE_TAG"
                        docker push "$IMAGE_NAME:latest"
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy Development') {
            when {
                expression { env.BRANCH_NAME == 'dev' }
            }
            steps {
                sshagent(credentials: ['app-server-ssh-key']) {
                    sh '''
                        set -eu
                        ssh -o StrictHostKeyChecking=accept-new \
                          "$APP_USER@$APP_HOST" \
                          "sudo docker pull $IMAGE_NAME:$IMAGE_TAG &&
                           sudo docker rm -f $CONTAINER_NAME &&
                           sudo docker run -d --name $CONTAINER_NAME \
                             --restart unless-stopped -p 80:80 \
                             $IMAGE_NAME:$IMAGE_TAG &&
                           curl -fsS http://localhost/ >/dev/null"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Image build and push completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Review Console Output.'
        }
    }
}
