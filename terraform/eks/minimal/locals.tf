locals {
  cluster_name = var.environment_name
  region       = data.aws_region.current.name
  account_id   = data.aws_caller_identity.current.account_id
}