# InnovateMart EKS Deployment - Project Bedrock

This repository contains the Infrastructure as Code (IaC) and CI/CD pipeline for deploying the InnovateMart retail store application on Amazon EKS.

## 🏗️ Architecture

- **EKS Cluster**: Production-grade Kubernetes cluster with managed node groups
- **VPC**: Custom networking with public/private subnets across 3 AZs
- **Application**: Microservices-based retail store with 5 core services
- **Security**: IAM roles with least privilege, read-only developer access
- **CI/CD**: Automated deployment pipeline with GitHub Actions

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured
- Terraform >= 1.5.0
- kubectl installed

### Deploy Infrastructure
```bash
cd terraform/eks/minimal
terraform init
terraform apply
```

### Deploy Application
```bash
aws eks --region eu-east-1 update-kubeconfig --name retail-store
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml
```

## 📁 Repository Structure


```
├── terraform/
│   └── eks/minimal/          # EKS infrastructure code
├── .github/workflows/        # CI/CD pipelines
├── DEPLOYMENT_GUIDE.md       # Detailed deployment instructions
└── README.md                 # This file
```

## 🔐 Security Features

- **IAM Roles**: Least privilege access for EKS cluster and nodes
- **Read-only Access**: Dedicated IAM user for development team
- **Network Security**: Private subnets for worker nodes
- **Encryption**: EKS cluster encrypted with KMS

## 🌐 Application Access

**Live Application**: http://k8s-default-ui-8c6cd7bbdd-f08607c24d54e805.elb.eu-north-1.amazonaws.com

## 👥 Developer Access

Read-only IAM user credentials and kubectl configuration instructions are provided in the [Deployment Guide](DEPLOYMENT_GUIDE.md).

## 🔄 CI/CD Pipeline

- **Pull Requests**: Trigger `terraform plan`
- **Main Branch**: Trigger `terraform apply`
- **Cleanup**: Enhanced destroy workflow with dependency handling
- **Security**: AWS credentials managed via GitHub secrets

## 📊 Monitoring

Check application status:
```bash
kubectl get pods --all-namespaces
kubectl get services
kubectl logs -f deployment/ui
```

## 🧹 Cleanup

**Automated (Recommended):**
- Use GitHub Actions: `Terraform Destroy Enhanced` workflow
- Handles dependencies and prevents deletion errors

**Manual:**
```bash
kubectl delete -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml
terraform destroy
```

## 📋 Assessment Completion

### ✅ Core Requirements Completed
- [x] Infrastructure as Code (Terraform)
- [x] EKS Cluster with VPC and IAM roles
- [x] Application deployment with in-cluster dependencies
- [x] Read-only developer IAM user
- [x] CI/CD pipeline with GitHub Actions

### 🎯 Bonus Objectives Available
- [ ] Managed AWS services (RDS, DynamoDB)
- [ ] Advanced networking with ALB Ingress
- [ ] Custom domain with SSL/TLS

---

**Project**: InnovateMart EKS Deployment  
**Status**: ✅ Production Ready  
**Team**: Cloud DevOps Engineering