variable "api_name" {
  description = "Application name"
  type = string
  default     = "filezip"
}

variable "vpc_id" {
  description = "Vpc Id"
  nullable    = false
  type = string
}

variable "vpc_link_subnets" {
  description = "Vpc subnets"
  nullable    = false
  type = list(string)
}

