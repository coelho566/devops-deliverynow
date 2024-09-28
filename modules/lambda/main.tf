resource "aws_lambda_function" "auth_function" {
  function_name = "lambda-deliverynow-auth"
  s3_bucket     = "deliverynow-bucket"
  s3_key        = "Lambda-Auth-1.0.jar"
  handler       = "authenticate.App::handleRequest"
  runtime       = "java21"
  memory_size   = 1024
  timeout       = 300
  role          = var.lambda_role

  architectures = ["x86_64"]

  tags = {
    Name = "lambda-deliverynow-auth"
  }
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.gateway_execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "api_integration" {
  api_id           = var.gateway_id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.auth_function.invoke_arn
}

resource "aws_apigatewayv2_route" "api_route" {
  api_id    = var.gateway_id
  route_key = "POST /authorization"

  target = "integrations/${aws_apigatewayv2_integration.api_integration.id}"
}