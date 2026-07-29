pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'nodejs-app'
        DOCKER_CREDENTIALS = 'docker-credentials'
        GIT_CREDENTIALS = 'github_cred'
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo '========== Checking Out Code =========='
                    checkout scm
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    echo '========== Running Tests =========='
                    sh '''
                        npm install
                        npm test
                    '''
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo '========== Building Application =========='
                    sh '''
                        npm run build
                    '''
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    echo '========== Building Docker Image =========='
                    sh '''
                        docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                    '''
                }
            }
        }
        
        stage('Docker Push') {
            steps {
                script {
                    echo '========== Pushing Docker Image =========='
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_USER}/${DOCKER_IMAGE}:${BUILD_NUMBER}
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin ${DOCKER_REGISTRY}
                            docker push ${DOCKER_USER}/${DOCKER_IMAGE}:${BUILD_NUMBER}
                            docker logout ${DOCKER_REGISTRY}
                        '''
                    }
                }
            }
        }

        stage('Update GitOps Repo') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${GIT_CREDENTIALS}",
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh '''
                    set -e

                    git clone https://github.com/${GIT_USER}/gitops_nodjsapp_sandbox.git
                    cd gitops_nodjsapp_sandbox
                    git checkout main

                    sed -i "s|image:.*|image: \"${DOCKER_USER}/${DOCKER_IMAGE}:${BUILD_NUMBER}\"|" nodejs-app-sandbox/values.yaml

                    git config user.name "${GIT_USER}"
                    git config user.email "${GIT_USER}@users.noreply.github.com"

                    git add .
                    git commit -m "Update image tag to ${BUILD_NUMBER}"
                    
                    git remote set-url origin https://${GIT_USER}:${GIT_TOKEN}@github.com/mahmoudSh58/gitops_nodjsapp_sandbox.git
                    git push origin main
                    '''
                }
            }
        }
        
    }
    
    post {
        always {
            cleanWs()
            echo '========== Pipeline Execution Complete =========='
        }
        success {
            echo '========== Build Success =========='
        }
        failure {
            echo '========== Build Failed =========='
        }
    }
}
