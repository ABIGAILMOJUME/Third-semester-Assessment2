#!/bin/bash

# Setup script for readonly development user

echo "Setting up readonly EKS access for development team..."

# Apply Terraform changes
cd terraform/eks/minimal
terraform apply -target=aws_iam_user.eks_readonly_dev -target=aws_iam_policy.eks_readonly -target=aws_iam_user_policy_attachment.eks_readonly_dev -target=kubernetes_cluster_role.readonly -target=kubernetes_cluster_role_binding.readonly

# Get credentials
ACCESS_KEY=$(terraform output -raw readonly_user_access_key)
SECRET_KEY=$(terraform output -raw readonly_user_secret_key)
USER_NAME=$(terraform output -raw readonly_user_name)

echo "=== READONLY USER CREDENTIALS ==="
echo "Username: $USER_NAME"
echo "Access Key: $ACCESS_KEY"
echo "Secret Key: $SECRET_KEY"
echo ""

echo "=== SETUP INSTRUCTIONS FOR DEVELOPERS ==="
echo "1. Configure AWS CLI profile:"
echo "   aws configure --profile readonly-dev"
echo "   AWS Access Key ID: $ACCESS_KEY"
echo "   AWS Secret Access Key: $SECRET_KEY"
echo "   Default region name: us-east-1"
echo ""
echo "2. Configure kubectl:"
echo "   aws eks --region us-east-1 update-kubeconfig --name retail-store --profile readonly-dev"
echo ""
echo "3. Test access:"
echo "   kubectl get pods --all-namespaces"
echo "   kubectl logs <pod-name> -n <namespace>"
echo "   kubectl describe pod <pod-name> -n <namespace>"
echo ""
echo "=== ALLOWED OPERATIONS ==="
echo "✓ View pods, services, deployments"
echo "✓ Read logs"
echo "✓ Describe resources"
echo "✓ List resources"
echo "✗ Create/Update/Delete resources"