locals {
  tags = {
    managed-by = "terraform"
    env        = var.env
  }

  cluster_name = "${var.env}-simetrik-eks-cluster-us1"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name                             = local.cluster_name
  cluster_version                          = var.cluster_version
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  tags = merge(local.tags, {
    "karpenter.sh/discovery" = local.cluster_name
  })
}
