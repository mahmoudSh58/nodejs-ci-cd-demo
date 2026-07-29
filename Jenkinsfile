pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'nodejs-app'
        DOCKER_CREDENTIALS = 'docker-credentials'
        ARGOCD_SERVER = 'http://23.20.3.55:8085/'
        ARGOCD_CREDENTIALS = 'argocd-credentials'
        GIT_REPO = 'your-git-repo-url'
        GIT_CREDENTIALS = 'git-credentials'
    }
    
    stages {
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
                        docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest
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
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin ${DOCKER_REGISTRY}
                            docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                            docker push ${DOCKER_IMAGE}:latest
                            docker logout ${DOCKER_REGISTRY}
                        '''
                    }
                }
            }
        }
        
        stage('Update ArgoCD') {
            steps {
                script {
                    echo '========== Updating ArgoCD Configuration =========='
                    withCredentials([usernamePassword(credentialsId: "${ARGOCD_CREDENTIALS}", usernameVariable: 'ARGOCD_USER', passwordVariable: 'ARGOCD_PASS')]) {
                        sh '''
                            # Login to ArgoCD
                            argocd login ${ARGOCD_SERVER} --username ${ARGOCD_USER} --password ${ARGOCD_PASS} --insecure
                            
                            # Update application image
                            argocd app set your-app-name -p image.tag=${BUILD_NUMBER}
                            
                            # Sync application
                            argocd app sync your-app-name --wait
                            
                            # Logout
                            argocd logout ${ARGOCD_SERVER}
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
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
