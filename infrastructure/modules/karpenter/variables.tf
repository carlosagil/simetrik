# tflint-ignore: terraform_unused_declarations
variable "eks_cluster_id" {
  description = "EKS cluster name"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.32"
}

variable "karpenter_version" {
  description = "The version of Karpenter to use"
  type        = string
  default = "1.3.3"
}