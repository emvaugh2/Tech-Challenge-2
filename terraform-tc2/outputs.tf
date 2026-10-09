output "flask_ecr_repository_url" {
  description = "ECR repository URL for the Flask application."
  value       = aws_ecr_repository.python_hcw.repository_url
}


output "jenkins_server_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller."
  value       = aws_iam_role.aws_load_balancer_controller_role.arn
}
output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for the EKS Cluster Autoscaler."
  value       = aws_iam_role.cluster_autoscaler_role.arn
}
output "jenkins_role_arn" {
  description = "IAM role ARN attached to the Jenkins EC2 instance."
  value       = aws_iam_role.jenkins_role.arn
}