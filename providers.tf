terraform {
  required_version = "~> 1.2.2"
  backend "s3" {
    region         = "us-east-2"
    bucket         = "vrising-terraform-state"
    key            = "terraform.tfstate"
    dynamodb_table = "vrising-terraform-state-lock"
    profile        = ""
    role_arn       = ""
    encrypt        = "true"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.17.0"
    }
    http = {
      source = "hashicorp/http"
      version = "2.2.0"
    }
  }
}
provider "aws" {
  region = var.region
  default_tags { tags = local.common_tags }
}

