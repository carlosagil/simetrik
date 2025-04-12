module "vpc" {
  source = "../../../modules/karpenter"

  eks_cluster_id = "dev-simetrik-eks-cluster-us1"
}
