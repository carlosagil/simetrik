variable "cluster_version" {
  description = "Version of the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "env" {
  description = "Environment tag (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "subnet_ids" {
  description = "List of subnet IDs (both public and private) to associate with the cluster"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC to associate with the cluster"
  type        = string
}