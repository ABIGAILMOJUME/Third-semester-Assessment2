#!/bin/bash

echo "🚀 Initializing Terraform Backend"
echo "=================================="

REGION="us-east-1"
ENV_NAME="retail-store"

# Step 1: Initialize without backend to create S3 bucket and DynamoDB table
echo "📦 Creating backend resources..."
terraform init
terraform apply -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_locks -auto-approve

# Step 2: Get the created bucket name
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
TABLE_NAME=$(terraform output -raw dynamodb_table_name)

echo "✅ Backend resources created:"
echo "   S3 Bucket: $BUCKET_NAME"
echo "   DynamoDB Table: $TABLE_NAME"

# Step 3: Configure backend
echo "🔧 Configuring remote backend..."
terraform init -backend-config="bucket=$BUCKET_NAME" \
                -backend-config="key=terraform.tfstate" \
                -backend-config="region=$REGION" \
                -backend-config="dynamodb_table=$TABLE_NAME" \
                -backend-config="encrypt=true"

echo "✅ Backend initialization complete!"
echo "💡 State is now stored remotely in S3 with DynamoDB locking"