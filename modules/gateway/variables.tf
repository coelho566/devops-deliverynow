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


variable "vpc_link_subnets" {
  description = "Vpc link subnets"  
  type = list(string)
  nullable = false
}

variable "vpc_id" {
  description = "Vpc id"  
  type    = string
  nullable = false
}
