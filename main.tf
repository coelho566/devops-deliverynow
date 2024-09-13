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


resource "aws_eks_cluster" "basic_app_cluster" {
  name     = "deliverynow-eks"
  role_arn = "arn:aws:iam::388512399861:role/LabRole"

  vpc_config {
    subnet_ids = [
      module.vpc.private_subnets[0],
      module.vpc.public_subnets[0],
      module.vpc.private_subnets[1],
      module.vpc.public_subnets[1],
      module.vpc.private_subnets[2],
      module.vpc.public_subnets[2]
    ]

    # security_group_ids = [aws_security_group.basic_app_eks_sg.id]
  }

  tags = {
    Name = "basic_app_cluster"
  }
}

resource "aws_eks_node_group" "basic_app_node_group" {
  cluster_name    = "deliverynow-eks"
  node_group_name = "basic_app_node_group"
  node_role_arn   = "arn:aws:iam::388512399861:role/LabRole"
  subnet_ids      = [
      module.vpc.private_subnets[0],
      module.vpc.private_subnets[1],
      module.vpc.private_subnets[2]
    ]

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }

  lifecycle {
    prevent_destroy = false
  }

  instance_types = ["t3.small"]
  disk_size      = 20

  # remote_access {
  #   ec2_ssh_key = var.ssh_key_name
  #   # source_security_group_ids = [aws_security_group.basic_app_sg.id]
  # }

  ami_type = "AL2_x86_64"

  depends_on = [aws_eks_cluster.basic_app_cluster]

  labels = {
    environment = "dev"
  }

  tags = {
    Name        = "basic_app_node_group"
    Environment = "dev"
  }
}