pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'nodejs-app'
        DOCKER_CREDENTIALS = 'docker-credentials'
        ARGOCD_SERVER = 'http://23.20.3.55:8085/'
        ARGOCD_CREDENTIALS = 'argocd-credentials'
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
                            docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_USER}/${DOCKER_IMAGE}:latest
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin ${DOCKER_REGISTRY}
                            docker push ${DOCKER_USER}/${DOCKER_IMAGE}:latest
                            docker push ${DOCKER_USER}/${DOCKER_IMAGE}:${BUILD_NUMBER}
                            docker logout ${DOCKER_REGISTRY}
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
