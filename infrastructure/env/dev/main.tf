module "vpc" {
  source = "../../modules/vpc"
}

module "eks" {
  source = "../../modules/eks"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  depends_on = [
    module.vpc
  ]
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
