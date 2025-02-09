terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.82.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "filezip-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  public_subnet_tags = {
    "kubernetes.io/cluster/filezip-eks" = "shared"
    "kubernetes.io/role/elb"                = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/filezip-eks" = "shared"
    "kubernetes.io/role/internal-elb"       = 1
  }

  tags = {
    Terraform                               = "true"
    Environment                             = "dev"
    Project                                 = "filezip"
    "kubernetes.io/cluster/filezip-eks" = "shared"
  }

}

module "ecr_service_filezip_management" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.0"

  repository_name = "service-filezip-management"

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

module "ecr_service_filezip_autentication" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.0"

  repository_name = "service-keycloak"

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

module "ecr_service_filezip_processor" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.0"

  repository_name = "service-filezip-processor"

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
  name     = "filezip-eks"
  role_arn = var.lab_role

  vpc_config {
    subnet_ids = [
      module.vpc.private_subnets[0],
      module.vpc.public_subnets[0],
      module.vpc.private_subnets[1],
      module.vpc.public_subnets[1]
    ]
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_eks_node_group" "basic_app_node_group" {
  cluster_name    = "filezip-eks"
  node_group_name = "basic_app_node_group"
  node_role_arn   = var.lab_role
  subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1]
  ]

  scaling_config {
    desired_size = 1
    max_size     = 5
    min_size     = 1
  }

  lifecycle {
    prevent_destroy = false
  }

  instance_types = ["t3.large"]
  disk_size      = 30

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


module "gateway" {
  source = "./modules/gateway"

  nlb_arn          = module.nlb.nlb_listener_arn
  nlb_dns          = module.nlb.nlb_dns
  vpc_id           = module.vpc.vpc_id
  vpc_link_subnets = module.vpc.public_subnets

}

resource "aws_s3_bucket" "filezip_terraform"{
  bucket = "filezip-terraform"
}

resource "aws_s3_bucket" "filezip_bucket"{
  bucket = "filezip-bucket-service"
}

resource "aws_sqs_queue" "process_queue"{
    name = "filezip-process-queue"
}

resource "aws_sqs_queue" "send_email_queue"{
    name = "filezip-send_email_queue"
}

# Criar uma política para permitir que o S3 publique mensagens na SQS
resource "aws_sqs_queue_policy" "s3_policy" {
  queue_url = aws_sqs_queue.process_queue.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "SQS:SendMessage",
        Resource  = aws_sqs_queue.process_queue.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.filezip_bucket.arn
          }
        }
      }
    ]
  })
}

# Criar a configuração de notificação no S3
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.filezip_bucket.id

  queue {
    queue_arn     = aws_sqs_queue.process_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "videos/"
    filter_suffix = ".mp4"
  }
}