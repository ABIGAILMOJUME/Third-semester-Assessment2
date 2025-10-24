# InnovateMart EKS Deployment - Deliverables

## Git Repository Link
**Repository**: `/home/omokaro/Desktop/retail-store-sample-app`
**Contents**: Complete IaC code, CI/CD pipelines, and Kubernetes manifests

## Deployment & Architecture Guide

### Architecture Overview

**Infrastructure Components:**
- **Amazon EKS Cluster** (minimal configuration)
- **VPC** with public/private subnets across multiple AZs
- **Managed Node Groups** for container workloads
- **Application Load Balancer** with SSL termination
- **Route 53** for DNS management
- **ACM Certificate** for HTTPS

**Application Components:**
- **UI Service** (Java) - Store frontend
- **Catalog Service** (Go) - Product catalog API
- **Cart Service** (Java) - Shopping cart API
- **Orders Service** (Java) - Order management API
- **Checkout Service** (Node.js) - Checkout orchestration

**CI/CD Pipeline:**
- **Terraform Infrastructure** - Automated EKS provisioning
- **Application Deployment** - Automated app deployment
- **GitFlow Strategy** - Feature branches → Plan, Main → Apply

### Access Instructions

#### 1. Deploy Infrastructure
```bash
cd terraform/eks/minimal
terraform init
terraform apply
```

#### 2. Configure kubectl
```bash
aws eks --region us-east-1 update-kubeconfig --name retail-store
```

#### 3. Deploy Application
```bash
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml
```

#### 4. Access Application
```bash
# Get LoadBalancer URL
kubectl get svc ui

# Access via browser
http://<LOAD_BALANCER_URL>
```

### Read-Only Developer IAM User

**Username**: `retail-store-eks-readonly-dev`

**Setup Instructions:**
```bash
# 1. Get credentials from Terraform output
terraform output readonly_user_access_key
terraform output readonly_user_secret_key

# 2. Configure AWS CLI profile
aws configure --profile readonly-dev
# Enter the access key and secret key from step 1

# 3. Configure kubectl
aws eks --region us-east-1 update-kubeconfig --name retail-store --profile readonly-dev

# 4. Test access
kubectl get pods --all-namespaces
kubectl logs <pod-name> -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

**Permissions:**
- ✅ View pods, services, deployments
- ✅ Read logs and describe resources
- ✅ List all Kubernetes resources
- ❌ Create, update, or delete resources

### Bonus Objectives Implementation

#### 1. AWS Load Balancer Controller
- **File**: `terraform/eks/minimal/alb-controller.tf`
- **Features**: IRSA role, Helm chart deployment
- **Benefits**: Native AWS ALB integration

#### 2. SSL/TLS with Custom Domain
- **Files**: 
  - `terraform/eks/minimal/route53-acm.tf` - DNS and certificates
  - `k8s/ingress.yaml` - Ingress with SSL
- **Domain**: `retailstore.example.com` (placeholder)
- **Certificate**: AWS Certificate Manager with DNS validation

#### 3. Advanced CI/CD Pipeline
- **Files**: 
  - `.github/workflows/terraform-infrastructure.yml`
  - `.github/workflows/app-deployment.yml`
- **Features**: 
  - Sequential workflows (infrastructure → application)
  - Secure credential management
  - Manual destroy workflow with confirmation

#### 4. Security Enhancements
- **S3 Backend**: State encryption and DynamoDB locking
- **RBAC**: Kubernetes role-based access control
- **IAM**: Least privilege access policies
- **Network**: Private subnets for worker nodes

### File Structure
```
retail-store-sample-app/
├── terraform/eks/minimal/
│   ├── main.tf                    # EKS cluster configuration
│   ├── iam-readonly.tf           # Read-only IAM user
│   ├── alb-controller.tf         # Load balancer controller
│   ├── route53-acm.tf           # DNS and SSL certificates
│   └── backend.tf               # S3 backend configuration
├── .github/workflows/
│   ├── terraform-infrastructure.yml
│   ├── app-deployment.yml
│   ├── terraform-plan.yml
│   ├── terraform-apply.yml
│   └── terraform-destroy.yml
├── k8s/
│   └── ingress.yaml             # ALB Ingress resource
└── docs/
    └── CICD_SETUP.md           # CI/CD setup guide
```

### Security Features
- ✅ No hardcoded credentials in code
- ✅ GitHub Secrets for AWS credentials
- ✅ Encrypted Terraform state in S3
- ✅ RBAC for read-only access
- ✅ SSL/TLS termination at ALB
- ✅ Private subnets for worker nodes