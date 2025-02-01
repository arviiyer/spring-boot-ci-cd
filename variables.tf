variable "region" {
  type        = string
  description = "AWS region to deploy resources in"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  type        = string
  description = "Name for the VPC"
  default     = "jenkins-lab-vpc"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "subnet_name" {
  type        = string
  description = "Name for the public subnet"
  default     = "jenkins-lab-public-subnet"
}

variable "availability_zone" {
  type        = string
  description = "Availability zone for the subnet"
  default     = "us-east-1a"
}

variable "igw_name" {
  type        = string
  description = "Name for the internet gateway"
  default     = "jenkins-lab-igw"
}

variable "route_table_name" {
  type        = string
  description = "Name for the route table"
  default     = "jenkins-lab-public-rt"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for the instances"
  default     = "ami-0f214d1b3d031dc53" # Replace with Debian 12 ARM64 AMI
}

variable "ssh_key_public" {
  type = string
  #Replace this with the location of you public key .pub
  default = "~/.ssh/id_rsa.pub"
}

variable "ssh_key_private" {
  type = string
  #Replace this with the location of you private key
  default = "~/.ssh/id_rsa"
}

variable "ecs_cluster_name" {
  type        = string
  description = "Name for the ECS cluster"
  default     = "arviiyer-spring-boot-cluster"
}

variable "ecs_service_name" {
  type        = string
  description = "Name for the ECS service"
  default     = "arviiyer-spring-boot-service"
}

variable "docker_image" {
  type        = string
  description = "Docker image name for ECS tasks"
  default     = "arviiyer/spring-boot-app"
}
