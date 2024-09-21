resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                            = "CognitoAuthorizer"
  rest_api_id                     = aws_api_gateway_rest_api.main.id
  type                            = "COGNITO_USER_POOLS"
  provider_arns                   = [var.cognito_arn]  # ID do seu User Pool
  identity_source                 = "method.request.header.Authorization"  # Header da autorização
}

resource "aws_api_gateway_vpc_link" "main" {
  name        = "foobar_gateway_vpclink"
  description = "Foobar Gateway VPC Link. Managed by Terraform."
  target_arns = [var.nlb_arn]
}

resource "aws_api_gateway_rest_api" "main" {
  name        = "foobar_gateway"
  description = "Foobar Gateway used for EKS. Managed by Terraform."
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "root_resource" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.root_resource.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"  # Habilitando autenticação Cognito
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id  # Referência ao authorizer criado

  request_parameters = {
    "method.request.path.proxy"           = true
    "method.request.header.Authorization" = true  # Exigindo o header de autorização
  }

  depends_on = [aws_api_gateway_resource.root_resource, aws_api_gateway_authorizer.cognito_authorizer]
}

# Configurando a integração HTTP_PROXY
resource "aws_api_gateway_integration" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root.http_method

  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.nlb_dns}/{proxy}"  # Substitua pelo DNS do NLB
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_TEXT"

  request_parameters = {
    "integration.request.path.proxy"           = "method.request.path.proxy"
    "integration.request.header.Accept"        = "'application/json'"
    "integration.request.header.Authorization" = "method.request.header.Authorization"  # Passa a autorização para o NLB
  }

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.main.id
  depends_on = [aws_api_gateway_method.root]
}

resource "aws_api_gateway_stage" "stage_dev" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "dev"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.main.body))
    auto_deploy  = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_integration.root]
}
