# Outputs for readonly user
output "readonly_user_access_key" {
  description = "Access key for readonly development user"
  value       = aws_iam_access_key.eks_readonly_dev.id
}

output "readonly_user_secret_key" {
  description = "Secret key for readonly development user"
  value       = aws_iam_access_key.eks_readonly_dev.secret
  sensitive   = true
}

output "readonly_user_name" {
  description = "IAM username for readonly access"
  value       = aws_iam_user.eks_readonly_dev.name
}

output "kubectl_config_readonly" {
  description = "kubectl configuration command for readonly user"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${local.cluster_name} --profile readonly-dev"
}

