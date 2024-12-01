terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.66.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "deliverynow-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  public_subnet_tags = {
    "kubernetes.io/cluster/deliverynow-eks" = "shared"
    "kubernetes.io/role/elb"                = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/deliverynow-eks" = "shared"
    "kubernetes.io/role/internal-elb"       = 1
  }

  tags = {
    Terraform                               = "true"
    Environment                             = "dev"
    Project                                 = "deliverynow"
    "kubernetes.io/cluster/deliverynow-eks" = "shared"
  }

}

module "ecr_application_deliverynow_user" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.0"

  repository_name = "application-deliverynow-user"

  repository_read_write_access_arns = [var.lab_role]
  repository_image_tag_mutability   = "MUTABLE"
  repository_encryption_type        = "AES256"

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

module "ecr_application_deliverynow_order" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.0"

  repository_name = "application-deliverynow-order"

  repository_read_write_access_arns = [var.lab_role]
  repository_image_tag_mutability   = "MUTABLE"
  repository_encryption_type        = "AES256"

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

module "ecr_application_deliverynow_product" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.0"

  repository_name = "application-deliverynow-product"

  repository_read_write_access_arns = [var.lab_role]
  repository_image_tag_mutability   = "MUTABLE"
  repository_encryption_type        = "AES256"

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
  role_arn = var.lab_role

  vpc_config {
    subnet_ids = [
      module.vpc.private_subnets[0],
      module.vpc.public_subnets[0],
      module.vpc.private_subnets[1],
      module.vpc.public_subnets[1],
      module.vpc.private_subnets[2],
      module.vpc.public_subnets[2]
    ]
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_eks_node_group" "basic_app_node_group" {
  cluster_name    = "deliverynow-eks"
  node_group_name = "basic_app_node_group"
  node_role_arn   = var.lab_role
  subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1],
    module.vpc.private_subnets[2]
  ]

  scaling_config {
    desired_size = 1
    max_size     = 5
    min_size     = 1
  }

  lifecycle {
    prevent_destroy = false
  }

  instance_types = ["t3.small"]
  disk_size      = 20

  ami_type = "AL2_x86_64"

  depends_on = [aws_eks_cluster.basic_app_cluster]

  labels = {
    environment = "dev"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "nlb" {
  source = "./modules/loadbalancer"

  vpc_id           = module.vpc.vpc_id
  vpc_link_subnets = module.vpc.public_subnets

  depends_on = [aws_eks_node_group.basic_app_node_group]
}

module "cognito" {
  source = "./modules/cognito"

  user_pool_name = "deliverynow-auth"
}

module "gateway" {
  source = "./modules/gateway"

  nlb_arn          = module.nlb.nlb_listener_arn
  nlb_dns          = module.nlb.nlb_dns
  cognito_arn      = module.cognito.arn
  vpc_id           = module.vpc.vpc_id
  vpc_link_subnets = module.vpc.public_subnets
  cognito_endpoint = module.cognito.cognito_endpoint
  cognito_id       = module.cognito.cognito_id

  depends_on = [module.cognito]
}

module "lambda" {
  source = "./modules/lambda"

  gateway_id            = module.gateway.api_id
  gateway_execution_arn = module.gateway.api_execution_arn
  lambda_role  = var.lab_role

  depends_on = [module.gateway]
}

module "secrets_manager" {
  source = "terraform-aws-modules/secrets-manager/aws"

  # Secret
  name             = "dev/cognito_secrets"
  description             = "Cognito secrets  "
  recovery_window_in_days = 7

  # Version
  ignore_secret_changes = true
  secret_string = jsonencode({
    appClientId   = module.cognito.cognito_id,
    userPoolId    = module.cognito.id,
    adminUser     = module.cognito.admin_username,
    adminPassword = module.cognito.admin_password
  })

  depends_on = [module.cognito]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

