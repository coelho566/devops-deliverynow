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

module "ecr_service-filezip-management" {
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

module "ecr_service-filezip-processor" {
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
  cluster_name    = "filezip-eks"
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

  depends_on = [module.nlb]
}

# Keycloak
module "rds_keycloak" {
  source                          = "terraform-aws-modules/rds/aws"
  identifier                      = "demo_aws_account_name-mariadb-keycloak-rds"
  allow_major_version_upgrade     = "true"
  engine                          = "mariadb"
  instance_class                  = "db.t3.medium"
  allocated_storage               = 40
  max_allocated_storage           = 100
  port                            = "3306"
  username                        = "keycloak"
  create_random_password          = false
  password                        = var.keycloak_password
  subnet_ids                      = [module.global_vpc.database_subnets[0], module.global_vpc.database_subnets[1]]
  vpc_security_group_ids          = [module.rds-keycloak-sg.security_group_id]
  maintenance_window              = "Sat:04:00-Sat:06:00"
  backup_window                   = "02:00-06:00"
  backup_retention_period         = 1
  copy_tags_to_snapshot           = true
  storage_encrypted               = true
  apply_immediately               = true
  skip_final_snapshot             = true
  auto_minor_version_upgrade      = true
  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]
  family                          = "mariadb10.6"
  major_engine_version            = "10.6"
  create_db_subnet_group          = true
  db_subnet_group_name            = "demo_aws_account_name-mariadb-keycloak-rds-subnetgroup"
  db_subnet_group_description     = "Managed by Terraform"
  db_subnet_group_use_name_prefix = false
  create_db_option_group          = true
  option_group_name               = "demo_aws_account_name-mariadb-keycloak-rds-optiongroup"
  option_group_use_name_prefix    = false
  option_group_description        = "Managed by Terraform"
  create_db_parameter_group       = true
  parameter_group_name            = "demo_aws_account_name-mariadb-keycloak-rds-parametergroup"
  parameter_group_use_name_prefix = false
  parameter_group_description     = "demo_aws_account_name-mariadb-keycloak-rds-parametergroup"

  tags = merge(
    var.tags,
    {
      Team       = "Blog"
      Project    = "Keycloak"
      Backup     = "true"
    },
  )
}

## ALB Keycloack ##
module "keycloak-internal-alb" {
  source = "terraform-aws-modules/alb/aws"

  name = "demo-keycloak-alb"

  load_balancer_type = "application"
  internal           = false
  vpc_id             = module.global_vpc.vpc_id
  subnets            = module.global_vpc.public_subnets
  security_groups    = [module.keycloak-internal-alb-sg.security_group_id]

  target_groups = [
    {
      name_prefix      = "keycl"
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/health"
        port                = "traffic-port"
        healthy_threshold   = 5
        unhealthy_threshold = 2
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  ]

  https_listeners = [
    {
      port                        = 443
      protocol                    = "HTTPS"
      listener_ssl_policy_default = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
      target_group_index          = 0
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      target_group_index = 0
    }
  ]

  tags = merge(
    var.tags,
    {
      Env         = "Blog"
      LegalEntity = "Demo"
      Project     = "Keycloak"
    }
  )
}

## ECS Cluster##
resource "aws_ecs_cluster" "demo-keycloak_ecs_cluster" {
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = "0"
    capacity_provider = "FARGATE"
    weight            = "1"
  }

  name = "demo_aws_account_name-keycloak-ecs"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = merge(
    var.tags,
    {
      Env         = "Demo"
      Project     = "Keycloak"
    }
  )
}

## ECS Cluster Service
resource "aws_ecs_service" "demo-keycloak_ecs_cluster_service" {
  capacity_provider_strategy {
    base              = "0"
    capacity_provider = "FARGATE"
    weight            = "1"
  }

  cluster = aws_ecs_cluster.demo-keycloak_ecs_cluster.name

  deployment_circuit_breaker {
    enable   = "false"
    rollback = "false"
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_maximum_percent         = "200"
  deployment_minimum_healthy_percent = "100"
  desired_count                      = "1"
  enable_ecs_managed_tags            = "true"
  enable_execute_command             = "true"
  health_check_grace_period_seconds  = "0"

  load_balancer {
    container_name   = "keycloak"
    container_port   = "8080"
    target_group_arn = module.keycloak-internal-alb.target_group_arns[0]
  }

  load_balancer {
    container_name   = "keycloak"
    container_port   = "8080"
    target_group_arn = module.keycloak-secound-internal-alb.target_group_arns[0]
  }

  name = "demo_aws_account_name-keycloak-service"

  network_configuration {
    assign_public_ip = "false"
    security_groups  = [aws_security_group.demo-ecs-keycloak-sg.id]
    subnets          = module.global_vpc.private_subnets
  }

  platform_version    = "LATEST"
  scheduling_strategy = "REPLICA"
  task_definition     = aws_ecs_task_definition.demo-keycloak_ecs_task_definition.arn
}

resource "aws_ecs_task_definition" "demo-keycloak_ecs_task_definition" {
  cpu                      = "1024"
  execution_role_arn       = aws_iam_role.ecs_keycloak.arn
  family                   = "keycloak"
  memory                   = "2048"
  container_definitions    = <<TASK_DEFINITION
[
  {
    "cpu": 0,
    "environment": [
      {"name": "AWS_REGION", "value": "eu-central-1"},
      {
          "name": "KC_PROXY",
          "value": "edge"
      },
      {
          "name": "AWS_REGION",
          "value": "eu-central-1"
      },
      {
          "name": "KC_DB_URL_PORT",
          "value": "3306"
      },
      {
          "name": "KC_DB_USERNAME",
          "value": "liquibase_keycloak"
      },
      {
          "name": "KC_DB",
          "value": "mariadb"
      },
      {
          "name": "KC_DB_URL_HOST",
          "value": "${module.rds_keycloak.db_instance_endpoint}"
      },
      {
          "name": "KC_HOSTNAME_STRICT",
          "value": "false"
      },
      {
          "name": "KC_HOSTNAME",
          "value": "auth.demo.cnl.io"
      },
      {
          "name": "KC_HEALTH_ENABLED",
          "value": "true"
      },
      {
          "name": "PROXY_ADDRESS_FORWARDING",
          "value": "true"
      }
    ],
    "secrets": [
      {"name": "KC_DB_PASSWORD", "valueFrom": "arn:aws:secretsmanager:eu-central-1:****:secret:keycloak/rds/credentials-xxyy:password::"}
    ],
    "essential": true,
    "image": "****.dkr.ecr.eu-central-1.amazonaws.com/cpe/quay.io/keycloak/keycloak:20.0.5",
    "logConfiguration": {
                          "logDriver":"awslogs",
                          "options": {
                                        "awslogs-group":"demo-ecs-keycloak-log-group",
                                        "awslogs-region": "eu-central-1",
                                        "awslogs-stream-prefix":"ecs"
                                      }
                        },
    "name": "keycloak",
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080,
        "protocol": "tcp"
      }
    ]
  }
]
TASK_DEFINITION
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_keycloak.arn

  runtime_platform {
    operating_system_family = "LINUX"
  }
  depends_on = [
    aws_cloudwatch_log_group.ecs_keycloak_log_log_group
  ]
}

