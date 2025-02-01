# Spring Boot Application with Docker and Jenkins CI/CD

## Overview
This project is a simple **Spring Boot** web application with REST APIs. It includes **Docker support** for containerization and a **Jenkins pipeline** for automated CI/CD deployment to **AWS ECS**.

## Features
- REST API with multiple endpoints.
- Packaged as a **Maven** project.
- Dockerized for easy deployment.
- CI/CD automation using **Jenkins**.
- Deploys to **AWS ECS**.

## Tech Stack
- **Java 8** (IBM JRE)
- **Spring Boot 2.6.3**
- **Maven**
- **Docker**
- **Jenkins**
- **AWS ECS**

## Setup & Installation
### **1. Clone the Repository**
```sh
 git clone https://github.com/arviiyer/spring-boot-app.git
 cd spring-boot-app
```

### **2. Build the Application**
```sh
 mvn clean install
```

### **3. Run the Application**
```sh
 java -jar target/*.jar
```
- The app will be available at `http://localhost:8080`

## Docker Setup
### **1. Build Docker Image**
```sh
 docker build -t spring-boot-app .
```
### **2. Run Docker Container**
```sh
 docker run -p 8080:8080 spring-boot-app
```

## Jenkins CI/CD Pipeline
### **Stages**
1. **Build** → Runs `mvn clean install`
2. **Build Docker Image** → Uses Jenkins Docker plugin
3. **Push to Docker Hub** → Uploads image to `dockerhub_login`
4. **Deploy to AWS ECS** → Updates the service

### **Jenkinsfile Configuration**
```groovy
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
                sh 'mvn clean install'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}")
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub_login') {
                        app.push("latest")
                    }
                }
            }
        }
        stage('Deploy to ECS') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh "aws ecs update-service --cluster ${ECS_CLUSTER} --service ${ECS_SERVICE} --force-new-deployment --region ${AWS_REGION}"
                }
            }
        }
    }
}
```

## License
This project is licensed under the **MIT License**.
