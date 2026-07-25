terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "agon-terraform-state-8066a6e1"
    key     = "dev/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "agon-health"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
