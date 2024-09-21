variable "nlb_arn" {
  description = "ARN of the load balancer"  
  type    = string
  nullable = false
}

variable "nlb_dns" {
  description = "DNS name of the load balancer"  
  type    = string
  nullable = false
}

variable "cognito_arn" {
  description = "Cognito arn"  
  type    = string
  nullable = false
}