output "configure_kubectl" {
  description = "Command to update kubeconfig for this cluster"
  value       = module.retail_app_eks.configure_kubectl
}

output "vpc_id" {
  description = "VPC ID for cleanup operations"
  value       = module.vpc.inner.vpc_id
}

# Backend resource outputs commented out since resources are managed externally
# output "s3_bucket_name" {
#   description = "S3 bucket name for state storage"
#   value       = "gabriel-eks-state-s3-bucket"
# }

# output "dynamodb_table_name" {
#   description = "DynamoDB table name for state locking"
#   value       = "retail-store-terraform-locks"
# }