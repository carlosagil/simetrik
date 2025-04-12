provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">= 1.3.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.83"
    }
  }

  backend "s3" {
    dynamodb_table = "gilcamargo-terraform-lock"
    bucket         = "gilcamargo-terraform"
    key            = "dev/simetrik"
    region         = "us-east-1"
  }
}
