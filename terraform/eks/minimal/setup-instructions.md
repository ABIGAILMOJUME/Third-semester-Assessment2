# Setup Instructions

## Step 1: Create Backend Resources
```bash
cd terraform/eks/minimal
terraform init
terraform apply -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_locks
```

## Step 2: Enable Backend
1. Uncomment the backend configuration in `backend.tf`
2. Run `terraform init` to migrate state to S3

## Step 3: Update Domain (Optional)
1. Edit `route53-acm.tf` - change `retailstore.example.com` to your domain
2. Or keep placeholder for demo purposes

## Step 4: Deploy Infrastructure
```bash
terraform apply
```

## Step 5: Get Certificate ARN
```bash
terraform output acm_certificate_arn
```

## Step 6: Update Ingress
Update `ingress.yaml` with the certificate ARN from step 5