terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.84.0"
    }
  }
  required_version = "~>1.10.2"
}

provider "aws" {
  region = var.region
}

# VPC and Subnet Resources
resource "aws_vpc" "jenkins_lab_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.jenkins_lab_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = {
    Name = var.subnet_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.jenkins_lab_vpc.id

  tags = {
    Name = var.igw_name
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.jenkins_lab_vpc.id

  tags = {
    Name = var.route_table_name
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "allow_http_ssh" {
  name        = "allow_http_ssh"
  description = "Security group to allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.jenkins_lab_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1233
    to_port     = 1233
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http_ssh"
  }
}

#Create key-pair
resource "aws_key_pair" "aws-key" {
  key_name   = "jenkins-kp"
  public_key = file(var.ssh_key_public)
}

# EC2 Instances
resource "aws_instance" "jenkins-server" {
  ami                         = var.ami_id
  instance_type               = "t2.small"
  subnet_id                   = aws_subnet.public_subnet.id
  key_name                    = aws_key_pair.aws-key.key_name
  vpc_security_group_ids      = [aws_security_group.allow_http_ssh.id]
  associate_public_ip_address = true

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.ssh_key_private)
      host        = self.public_ip
    }

    source      = "install_jenkins_and_docker.yaml"
    destination = "install_jenkins_and_docker.yaml"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.ssh_key_private)
      host        = self.public_ip
    }

    inline = [
      "sudo yum update -y && sudo amazon-linux-extras install ansible2 -y && sudo amazon-linux-extras install java-openjdk11 -y",
      "sleep 60s",
      "ansible-playbook install_jenkins_and_docker.yaml"
    ]
  }

  tags = {
    Name = "Jenkins-server"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "spring_boot_cluster" {
  name = var.ecs_cluster_name
}

# ECS Task Execution IAM Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "spring_boot_task" {
  family                   = "spring-boot-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "spring-boot-container"
    image     = "${var.docker_image}:latest"
    essential = true
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
      protocol      = "tcp"
    }]
  }])
}

# ECS Service
resource "aws_ecs_service" "spring_boot_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.spring_boot_cluster.id
  task_definition = aws_ecs_task_definition.spring_boot_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.allow_http_ssh.id]
    assign_public_ip = true
  }
}
