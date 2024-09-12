terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.66.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "deliverynow-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
  Terraform   = "true"
  Environment = "dev"
  Project     = "deliverynow"
  Teste     = "ok"
}

}

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"
  version = "2.3.0"

  repository_name = var.aws_ecr_name

  repository_read_write_access_arns = ["arn:aws:iam::388512399861:role/LabRole"]
  repository_image_tag_mutability = "MUTABLE"
  repository_encryption_type = "AES256"

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "secrets_manager" {
  source = "terraform-aws-modules/secrets-manager/aws"

  name            = "secrets/db-config"
  secret_string   = jsonencode({
      DB_HOST     = var.aws_region ,
      DB_USER     = "user",
      DB_PASSWORD = "password"
  })

  # Policy
  create_policy       = true
  block_public_policy = true
  policy_statements = {
    lambda = {
      sid = "ApplicationReadWrite"
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::388512399861:role/LabRole"]
      }]
      actions = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue",
        "secretsmanager:UpdateSecretVersionStage",
      ]
      resources = ["*"]
    }
    read = {
      sid = "AllowAccountRead"
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::388512399861:role/LabRole"]
      }]
      actions   = ["secretsmanager:DescribeSecret"]
      resources = ["*"]
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

