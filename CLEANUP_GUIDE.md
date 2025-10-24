# Cleanup Guide - InnovateMart EKS Deployment

## 🚨 Important: Proper Cleanup Order

AWS resources have dependencies that must be cleaned up in the correct order to avoid errors like:
- `DependencyViolation: The subnet has dependencies and cannot be deleted`
- `DependencyViolation: The vpc has dependencies and cannot be deleted`

## 🤖 Automated Cleanup (Recommended)

### Using GitHub Actions Workflow

1. **Navigate to Actions tab** in your GitHub repository
2. **Select "Terraform Destroy Enhanced"** workflow
3. **Click "Run workflow"**
4. **Enter "destroy"** in the confirmation field
5. **Choose cleanup target:**
   - `all`: Complete cleanup (application + infrastructure)
   - `app-only`: Remove only Kubernetes application
   - `infrastructure-only`: Remove only Terraform infrastructure

### Workflow Features
- ✅ **Dependency-aware cleanup** in correct order
- ✅ **LoadBalancer cleanup** before subnet deletion
- ✅ **Security group cleanup** before VPC deletion
- ✅ **Retry logic** for transient failures
- ✅ **Backend cleanup** (S3 bucket and DynamoDB table)

## 🔧 Manual Cleanup

### Step 1: Remove Kubernetes Application
```bash
# Delete application resources
kubectl delete -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml

# Verify LoadBalancer services are deleted
kubectl get svc --all-namespaces | grep LoadBalancer
```

### Step 2: Clean Up AWS LoadBalancers
```bash
# List and delete EKS-created LoadBalancers
aws elbv2 describe-load-balancers --region eu-north-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-`)].LoadBalancerArn' \
  --output text | while read lb_arn; do
    echo "Deleting LoadBalancer: $lb_arn"
    aws elbv2 delete-load-balancer --load-balancer-arn $lb_arn --region eu-north-1
done
```

### Step 3: Wait for AWS Cleanup
```bash
# Wait for LoadBalancers to be fully deleted
sleep 60
```

### Step 4: Destroy Terraform Infrastructure
```bash
cd terraform/eks/minimal
terraform destroy -auto-approve
```

### Step 5: Handle Remaining Dependencies (if needed)
```bash
# If VPC deletion fails, clean up security groups
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null)
aws ec2 describe-security-groups --region eu-north-1 \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
  --output text | tr '\t' '\n' | while read sg_id; do
    echo "Deleting security group: $sg_id"
    aws ec2 delete-security-group --group-id $sg_id --region eu-north-1
done

# Retry terraform destroy
terraform destroy -auto-approve
```

## 🔍 Troubleshooting Common Issues

### Issue: Subnet Deletion Fails
**Cause:** LoadBalancer or Network Interfaces still attached
**Solution:** 
```bash
# Check for remaining network interfaces
aws ec2 describe-network-interfaces --region eu-north-1 \
  --filters "Name=vpc-id,Values=<VPC_ID>" \
  --query 'NetworkInterfaces[].NetworkInterfaceId'

# Delete if found
aws ec2 delete-network-interface --network-interface-id <ENI_ID>
```

### Issue: VPC Deletion Fails
**Cause:** Security groups or Internet Gateway dependencies
**Solution:**
```bash
# Delete non-default security groups first
# Then retry terraform destroy
```

### Issue: LoadBalancer Stuck in Deleting State
**Cause:** Target groups or listeners not cleaned up
**Solution:**
```bash
# Wait longer (up to 10 minutes) or force delete via AWS Console
```

## 📊 Verification Commands

### Check Remaining Resources
```bash
# Check EKS cluster
aws eks describe-cluster --name retail-store --region eu-north-1

# Check LoadBalancers
aws elbv2 describe-load-balancers --region eu-north-1

# Check VPC resources
aws ec2 describe-vpcs --region eu-north-1 --filters "Name=tag:Name,Values=*retail-store*"
```

### Verify Complete Cleanup
```bash
# Should return empty or error (cluster not found)
kubectl get nodes 2>/dev/null || echo "Cluster successfully deleted"

# Check AWS resources
aws resourcegroupstaggingapi get-resources --region eu-north-1 \
  --tag-filters Key=environment-name,Values=retail-store
```

## 💰 Cost Optimization

**Important:** Always clean up resources to avoid ongoing charges:
- EKS cluster: ~$0.10/hour
- EC2 instances: ~$0.05-0.10/hour per instance
- LoadBalancers: ~$0.025/hour
- NAT Gateways: ~$0.045/hour

**Total estimated cost if left running: ~$5-10/day**

---
**Remember:** Use the automated GitHub Actions workflow for the safest cleanup experience!