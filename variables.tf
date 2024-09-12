variable "aws_region" {
  description = "Região usada para criar os recursos da AWS"
  type        = string
  nullable    = false
}

variable "aws_ecr_name" {
  description = "Colocar sempre a descrição"
  type        = string
  nullable    = false
}
