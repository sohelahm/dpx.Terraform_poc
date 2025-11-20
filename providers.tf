# Provider configuration for AWS
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  # Backend configuration for storing state
    backend "s3" {
    # These values will be provided via backend config in the workflow
    # bucket = "your-terraform-state-bucket"
    # key    = "environment/terraform.tfstate"
    # region = "us-east-1"
      encrypt        = true
     dynamodb_table = "terraform-state-lock"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  # Default tags for all resources
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedBy   = "GitHub-Actions"
      Repository  = "aws-terraform-cloudwatch"
    }
  }
}

# Data source to get current AWS region
data "aws_region" "current" {}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get current AWS partition
data "aws_partition" "current" {}

# Random suffix for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}
