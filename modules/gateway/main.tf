module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 5.1.2"

  name          = "gateway-deliverynow"
  description   = "BMB HTTP API Gateway"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  # Access logs
  stage_access_log_settings = {
    create_log_group            = true
    log_group_retention_in_days = 1
    format = jsonencode({
      context = {
        domainName              = "$context.domainName"
        integrationErrorMessage = "$context.integrationErrorMessage"
        protocol                = "$context.protocol"
        requestId               = "$context.requestId"
        requestTime             = "$context.requestTime"
        responseLength          = "$context.responseLength"
        routeKey                = "$context.routeKey"
        stage                   = "$context.stage"
        status                  = "$context.status"
        error = {
          message      = "$context.error.message"
          responseType = "$context.error.responseType"
        }
        identity = {
          sourceIP = "$context.identity.sourceIp"
        }
        integration = {
          error             = "$context.integration.error"
          integrationStatus = "$context.integration.integrationStatus"
        }
      }
    })
  }

  create_domain_name = false

    # Authorizer(s)
  authorizers = {
    cognito = {
      authorizer_type  = "JWT"
      identity_sources = ["$request.header.Authorization"]
      name             = "cognito"
      jwt_configuration = {
        audience = [var.cognito_id]
        issuer   = "https://${var.cognito_endpoint}"
      }
    }
  }

  # Routes & Integration(s)
  routes = {
    "ANY /{proxy+}" = {
      authorization_type   = "JWT"
      authorizer_key       = "cognito"
      integration = {
        connection_type = "VPC_LINK"
        type            = "HTTP_PROXY"
        uri             = var.nlb_arn
        method          = "ANY"
        vpc_link_key    = "bmb-vpc"
      }
    }
  }

  # VPC Link
  vpc_links = {
    bmb-vpc = {
      name               = "gateway-deliverynow-vpc_link"
      security_group_ids = [module.api_gateway_security_group.security_group_id]
      subnet_ids         = var.vpc_link_subnets
    }
  }

  tags = {
    Created   = timestamp()
    Terraform = "true"
  }
}

module "api_gateway_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1.2"

  name        = "deliverynow-vpclink-sg"
  description = "API Gateway group for example usage"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]

  egress_rules = ["all-all"]

  tags = {
    Terraform = "true"
    Created   = timestamp()
  }
}