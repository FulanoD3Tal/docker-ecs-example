terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.15.0"
    }
  }
  backend "s3" {
    bucket = "ecs-s3-bucket-test"
    region = "us-east-1"
    key    = "terraform/ecs"
  }
}

provider "aws" {
  region = var.aws_region
}
