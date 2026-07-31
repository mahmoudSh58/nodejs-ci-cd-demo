pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'nodejs-app'
        DOCKER_CREDENTIALS = 'docker-credentials'
        NEXUS_CREDENTIALS = 'nexus-credentials'
        GIT_CREDENTIALS = 'github_cred'
        DOCKER_USER = 'mahmoud58'
        N8N_WEBHOOK_URL = 'https://theadmin123.app.n8n.cloud/webhook-test/f76365dd-7d10-4563-9764-be44915ca92c'
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

        // stage('Edit Nexus .npmrc and Dockerfile') {
        //     steps {
        //         script {
        //             echo '========== Editing .npmrc for Nexus =========='
        //             withCredentials([usernamePassword(credentialsId: "${NEXUS_CREDENTIALS}", usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
        //                 sh '''
        //                     set -e
        //                     sed -i "s|^registry=.*|registry=http://${NEXUS_USER}:${NEXUS_PASS}@54.198.52.20:8081/repository/npm-proxy/|" .npmrc
        //                     sed -i "s|^ENV NPM_CONFIG_REGISTRY=.*|ENV NPM_CONFIG_REGISTRY=http://${NEXUS_USER}:${NEXUS_PASS}@54.198.52.20:8081/repository/npm-proxy/|" Dockerfile
        //                 '''
        //             }
        //         }
        //     }
        // }

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

                    ls namespaces/sandbox.yaml && rm namespaces/sandbox.yaml || echo "sandbox.yaml does not exist, proceeding to create it."
                    cp namespaces/production.yaml namespaces/sandbox.yaml
                    sed -i "s|namespace:.*|namespace: sandbox|" namespaces/sandbox.yaml
                    sed -i "s|image:.*|image: \"${DOCKER_USER}/${DOCKER_IMAGE}:${BUILD_NUMBER}\"|" namespaces/sandbox.yaml
                    sed -i "s|replicaCount:.*|replicaCount: 1|" namespaces/sandbox.yaml

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

        stage('wait for 90 seconds') {
            steps {
                script {
                    echo '========== Waiting for 90 seconds =========='
                    sleep(time: 90, unit: "SECONDS")
                }
            }
        }
        
        stage('Trigger n8n Workflow') {
            steps {
                script {
                    echo '========== Triggering n8n Workflow =========='
                    sh '''
                        curl -X POST \
                            -H "Content-Type: application/json" \
                            -d '{"build_number":"'"${BUILD_NUMBER}"'" , "image":"'"${DOCKER_USER}/${DOCKER_IMAGE}:${BUILD_NUMBER}"'"}' \
                            "${N8N_WEBHOOK_URL}"
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
