

# Get the AWS account ID dynamically
data "aws_caller_identity" "current" {}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = yamlencode([{
    #   userarn  = "arn:aws:iam::${var.account_id}:user/dev_user"
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/dev_user"
      username = "dev_user"
      groups   = ["readonly-group"]
    }])
  }
}

resource "kubernetes_cluster_role" "readonly" {
  metadata {
    name = "readonly-role"
  }
  rule {
    api_groups = [""]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["apps", "extensions"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "readonly_binding" {
  metadata {
    name = "readonly-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.readonly.name
  }
  subject {
    kind      = "User"
    name      = "dev_user"
    api_group = "rbac.authorization.k8s.io"
  }
}
