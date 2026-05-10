pipeline {
    agent any

    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['staging', 'production', 'both'], description: 'Choose environment to deploy')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Check this to skip Unit Tests and Linting')
    }

    tools {
        nodejs 'Node18'
    }

    environment {
        DOCKER_USER  = 'r0bert000'
        IMAGE_NAME   = 'shopflow-enterprise'
        IMAGE_TAG    = "${env.BUILD_NUMBER}"
        DOCKER_CREDS = credentials('docker-hub-creds')
    }

    stages {
        stage('Preparation') {
            steps {
                cleanWs()
                checkout scm
            }
        }

        stage('Quality Gate (Parallel)') {
            when { expression { params.SKIP_TESTS == false } }
            parallel {
                stage('Unit Tests') {
                    steps { sh 'npm install && npm test' }
                }
                stage('Linting') {
                    steps { sh 'npm run lint' }
                }
            }
        }

        stage('Build & Push Image') {
            steps {
                retry(3) {
                    sh "docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
                    sh "echo \$DOCKER_CREDS_PSW | docker login -u \$DOCKER_CREDS_USR --password-stdin"
                    sh "docker push ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
                sh "docker tag ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_USER}/${IMAGE_NAME}:latest"
                sh "docker push ${DOCKER_USER}/${IMAGE_NAME}:latest"
            }
        }

        stage('Deploy to Staging') {
            when { expression { params.DEPLOY_ENV in ['staging', 'both'] } }
            steps {
                sh """
                    docker rm -f shopflow-staging 2>/dev/null || true
                    sleep 2
                    docker run -d --name shopflow-staging -p 3001:3000 \
                      -e NODE_ENV=staging ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Approval Gate') {
            when { expression { params.DEPLOY_ENV in ['production', 'both'] } }
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        input message: 'Does Staging look good? Deploy to Production?', ok: 'Deploy!'
                    }
                }
            }
        }

        stage('Deploy to Production') {
            when { expression { params.DEPLOY_ENV in ['production', 'both'] } }
            steps {
                sh """
                    docker rm -f shopflow-prod 2>/dev/null || true
                    sleep 2
                    docker run -d --name shopflow-prod -p 3002:3000 \
                      -e NODE_ENV=production ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }

    post {
        always {
            echo 'Cleaning up Docker environment...'
            sh 'docker logout'
            sh 'docker image prune -f'
            cleanWs()
        }
        success {
            echo "✅ ShopFlow Build #${env.BUILD_NUMBER} Deployed Successfully!"
        }
        failure {
            echo "❌ ALERT: Build #${env.BUILD_NUMBER} Failed! Check logs immediately."
        }
    }
}
