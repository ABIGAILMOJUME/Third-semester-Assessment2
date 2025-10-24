#!/bin/bash

# Setup domain configuration

echo "Domain Setup Instructions:"
echo "=========================="
echo ""
echo "1. Register a domain (free options):"
echo "   - Freenom: https://freenom.com"
echo "   - Dot.tk: https://dot.tk"
echo "   - Or use AWS Route 53 to register"
echo ""
echo "2. Update domain in Terraform:"
echo "   Edit terraform/eks/minimal/route53-acm.tf"
echo "   Change 'retailstore.example.com' to your domain"
echo ""
echo "3. After terraform apply, get certificate ARN:"
echo "   terraform output acm_certificate_arn"
echo ""
echo "4. Update ingress.yaml with certificate ARN:"
echo "   Replace 'arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERTIFICATE_ID'"
echo "   with the actual ARN from step 3"
echo ""

# Get current AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Your AWS Account ID: $ACCOUNT_ID"
echo ""
echo "Example certificate ARN format:"
echo "arn:aws:acm:us-east-1:$ACCOUNT_ID:certificate/12345678-1234-1234-1234-123456789012"