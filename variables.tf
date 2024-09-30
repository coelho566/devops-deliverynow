variable "aws_region" {
  description = "Região usada para criar os recursos da AWS"
  type        = string
  nullable    = false
  default     = "us-east-1"
}

variable "aws_ecr_name" {
  description = "Colocar sempre a descrição"
  type        = string
  nullable    = false
  default     = "deliverynow-ecr"
}


variable "lab_role" {
  description = "Role aws lab"
  type        = string
  nullable    = false
  default     = "arn:aws:iam::755211177052:role/LabRole"
}