# Updated backend configuration
terraform {
  required_version = ">= 1.0.0"

#  backend "s3" {
 #   bucket         = "gabriel-eks-state-s3-bucket"
 #   key            = "terraform.tfstate"
 #   region         = "eu-north-1"
  #  dynamodb_table = "retail-store-terraform-locks"
  #  encrypt        = true
  #}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0, < 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0, < 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0, < 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0, < 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.0, < 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7, < 1.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.0, < 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0, < 4.0"
    }
  }
}

provider "aws" {
}

provider "kubernetes" {
  host                   = module.retail_app_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.retail_app_eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}



provider "helm" {
  kubernetes {
    host                   = module.retail_app_eks.cluster_endpoint
    token                  = data.aws_eks_cluster_auth.this.token
    cluster_ca_certificate = base64decode(module.retail_app_eks.cluster_certificate_authority_data)
  }
}
