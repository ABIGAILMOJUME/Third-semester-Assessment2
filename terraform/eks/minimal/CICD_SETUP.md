# CI/CD Pipeline Setup Guide

## Overview
This project uses GitHub Actions with GitFlow branching strategy for automated Terraform deployments.

## Branching Strategy
- **main**: Production deployments (terraform apply)
- **develop**: Development environment
- **feature/***: Feature branches (terraform plan only)

## Pipeline Triggers
- **Feature branches**: `terraform plan` on push
- **Pull requests**: `terraform plan` for validation
- **Main branch**: `terraform apply` on merge

## Setup Instructions

### 1. Create S3 Backend Resources
```bash
# Create S3 bucket for state
aws s3 mb s3://retail-store-terraform-state --region us-east-1

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name retail-store-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### 2. Configure GitHub Secrets
In your GitHub repository, add these secrets:
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

### 3. Workflow Files
- `.github/workflows/terraform-ci-cd.yml`: Main Terraform pipeline
- `.github/workflows/app-deployment.yml`: Application deployment

## Security Features
- ✅ AWS credentials stored as GitHub secrets
- ✅ No hardcoded credentials in code
- ✅ S3 backend with encryption
- ✅ DynamoDB state locking
- ✅ Branch protection rules

## Usage
1. Create feature branch: `git checkout -b feature/new-feature`
2. Make changes and push: triggers `terraform plan`
3. Create PR to main: triggers validation
4. Merge to main: triggers `terraform apply`

## Manual Destroy
Use GitHub Actions manual trigger for `terraform destroy` when needed.