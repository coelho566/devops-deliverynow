variable "gateway_id" {
  description = "Aws gateway deliverynow id"
  type        = string
  nullable    = false
}

variable "gateway_execution_arn" {
  description = "Aws gateway execution arn"
  type        = string
  nullable    = false
}

variable "lambda_role" {
  description = "Aws lambda role"
  type        = string
  nullable    = false
}