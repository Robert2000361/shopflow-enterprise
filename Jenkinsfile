pipeline {
    agent any
    
    // القسم الجديد: يتيح لك خيارات قبل بدء التشغيل
    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['staging', 'production'], description: 'Choose environment to focus on')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Check this to skip Unit Tests and Linting')
    }

    tools {
        nodejs 'Node18'
    }

    environment {
        DOCKER_USER = 'r0bert000'
        IMAGE_NAME  = 'shopflow-enterprise'
        IMAGE_TAG   = "${env.BUILD_NUMBER}"
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
            // لن تعمل هذه المرحلة إلا إذا كان خيار SKIP_TESTS غير مفعل (false)
            when { expression { params.SKIP_TESTS == false } }
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'npm install && npm test'
                    }
                }
                stage('Linting') {
                    steps {
                        sh 'npm run lint'
                    }
                }
            }
        }

        stage('Build & Push Image') {
            steps {
                sh "docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
                sh "echo \$DOCKER_CREDS_PSW | docker login -u \$DOCKER_CREDS_USR --password-stdin"
                sh "docker push ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                sh "docker tag ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_USER}/${IMAGE_NAME}:latest"
                sh "docker push ${DOCKER_USER}/${IMAGE_NAME}:latest"
            }
        }

        
        stage('Deploy to Staging') {
            steps {
                echo "Cleaning up old container and deploying to Staging..."
                // الأمر السحري: بيمسح القديم لو موجود، ولو مش موجود بيكمل عادي من غير ما يخرج بخطأ
                sh "docker rm -f shopflow-staging || true" 
                sh "docker run -d --name shopflow-staging -p 3001:3000 -e NODE_ENV=staging ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Approval Gate') {
            steps {
                input message: "Does the Staging look good? Deploy to Production?", ok: "Deploy!"
            }
        }

        
        stage('Deploy to Production') {
            steps {
                echo "Cleaning up old container and deploying to Production..."
                sh "docker rm -f shopflow-prod || true"
                sh "docker run -d --name shopflow-prod -p 3002:3000 -e NODE_ENV=production ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }

    post {
        always {
            sh "docker logout"
        }
        success {
            echo "Successfully deployed ShopFlow Build #${IMAGE_TAG}"
        }
    }
}