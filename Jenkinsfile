pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "arviiyer/spring-boot-app"
        ECS_CLUSTER = "arviiyer-spring-boot-cluster"
        ECS_SERVICE = "arviiyer-spring-boot-service"
        AWS_REGION = "us-east-1"
    }

    stages {
        stage('Build') {
            steps {
                echo 'Starting Maven Build'
                sh 'mvn clean install'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker Image'
                    app = docker.build("${DOCKER_IMAGE}")
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                script {
                    echo 'Pushing Docker Image'
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub_login') {
                        app.push("${env.BUILD_NUMBER}")
                        app.push("latest")
                    }
                }
            }
        }
        stage('Deploy to ECS') {
            steps {
                withCredentials([[
                    $class: 'UsernamePasswordMultiBinding',
                    credentialsId: 'aws-key',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        echo 'Deploying to ECS Cluster'
                        sh """
                            aws ecs update-service \
                                --cluster ${ECS_CLUSTER} \
                                --service ${ECS_SERVICE} \
                                --force-new-deployment \
                                --region ${AWS_REGION}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully. Image deployed to ECS.'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
