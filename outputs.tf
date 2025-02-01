output "Jenkins-Public-URL" {
  value = "http://${aws_instance.jenkins-server.public_ip}:8080"
}

output "ECS_Cluster_Name" {
  value = aws_ecs_cluster.spring_boot_cluster.name
}

output "ECS_Service_Name" {
  value = aws_ecs_service.spring_boot_service.name
}

