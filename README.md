# CI/CD Pipeline with Docker, Jenkins, and Terraform

## Overview

This project demonstrates an automated **CI/CD pipeline** using **Jenkins**, **Docker**, and **Terraform** to build, containerize, and deploy applications to **AWS ECS**. The provided infrastructure provisioning scripts allow easy setup of a Jenkins server and an ECS cluster.

> **Note:** The included Spring Boot application is just a sample to showcase the pipeline. You can replace it with any application of your choice. The primary goal is to highlight the automation of container building and deployment using Jenkins.

## Features

- Fully automated CI/CD pipeline with **Jenkins**.
- Dockerized application for seamless container deployment.
- **Terraform scripts** to provision AWS infrastructure.
- Continuous deployment to **AWS ECS Fargate**.
- Sample **Spring Boot** web application for demonstration (can be replaced).

## Tech Stack

- **Jenkins**
- **Docker**
- **Terraform**
- **AWS ECS**
- **Spring Boot (Sample Application)**
- **Maven**

## Setup & Installation

### **1. Clone the Repository**

```sh
 git clone https://github.com/arviiyer/spring-boot-app.git
 cd spring-boot-app
```

### **2. Build the Sample Application** *(Optional if using a different application)*

```sh
 mvn clean install
```

### **3. Run the Sample Application Locally** *(Optional)*

```sh
 java -jar target/*.jar
```

- The app will be available at `http://localhost:8080`

## Docker Setup

### **1. Build Docker Image**

```sh
 docker build -t sample-app .
```

### **2. Run Docker Container**

```sh
 docker run -p 8080:8080 sample-app
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
        DOCKER_IMAGE = "arviiyer/sample-app" // Change this to your Docker Hub repository if using a different one
        ECS_CLUSTER = "arviiyer-ecs-cluster" // Modify to match your ECS cluster name
        ECS_SERVICE = "arviiyer-ecs-service" // Modify to match your ECS service name
        AWS_REGION = "us-east-1" // Update this to the AWS region you are using
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
                        docker.build("${DOCKER_IMAGE}").push("latest")
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

## Infrastructure Setup with Terraform

This project provides **Terraform scripts** to set up a **Jenkins CI/CD server on AWS EC2** and deploy an application to **AWS ECS using Fargate**.

### **1. Prerequisites**

Before running Terraform, ensure you have:

- **Terraform** installed ([Installation Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli))
- **AWS CLI** installed and configured
- An **AWS account** with necessary permissions

### **2. Initialize Terraform**

```sh
terraform init
```

This downloads necessary provider plugins.

### **3. Apply Terraform to Provision Infrastructure**

Run the following command to deploy the **Jenkins Server and ECS Cluster**:

```sh
terraform apply
```

### **4. Access Jenkins Server**

After deployment, get the **Jenkins URL**:

```sh
terraform output Jenkins-Public-URL
```

Open it in your browser:

```
http://<JENKINS_PUBLIC_IP>:8080
```

### **5. Deploy to AWS ECS**

Once Jenkins is up, push a change to the repo to trigger the pipeline. The application will be deployed to **AWS ECS**.

### **6. Destroy Infrastructure (Optional)**

To remove all resources:

```sh
terraform destroy 
```

## License

This project is licensed under the [MIT License]\(./LICENSE).
