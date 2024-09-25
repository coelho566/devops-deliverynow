output "id" {
  value = aws_cognito_user_pool.bmb_user_pool.id
}

output "arn" {
  value = aws_cognito_user_pool.bmb_user_pool.arn
}

output "cognito_endpoint" {
  value = aws_cognito_user_pool.bmb_user_pool.endpoint
}

output "cognito_id" {
  value = aws_cognito_user_pool_client.bmb_test_client.id
}