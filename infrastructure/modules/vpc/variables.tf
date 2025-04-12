variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name to assign to the VPC and its related resources"
  type        = string
  default     = "simetrik-vpc-us1"
}

variable "env" {
  description = "Environment tag (e.g., dev, prod)"
  type        = string
  default     = "dev"
}
