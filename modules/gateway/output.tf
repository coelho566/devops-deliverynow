output "base_url" {
  value = "${aws_api_gateway_stage.stage_dev.invoke_url}/"
}