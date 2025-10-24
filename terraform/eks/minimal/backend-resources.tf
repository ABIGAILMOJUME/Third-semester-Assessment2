# Backend resources already exist and are managed outside Terraform
# S3 bucket: gabriel-eks-state-s3-bucket
# DynamoDB table: retail-store-terraform-locks

# Commented out to avoid conflicts with existing resources
# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "gabriel-eks-state-s3-bucket"
# }

# resource "aws_dynamodb_table" "terraform_locks" {
#   name           = "retail-store-terraform-locks"
#   billing_mode   = "PAY_PER_REQUEST"
#   hash_key       = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }

#   server_side_encryption {
#     enabled = true
#   }
# }