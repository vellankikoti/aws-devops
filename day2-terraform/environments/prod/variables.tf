variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "sockshop"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "instance_type" {
  type    = string
  default = "t2.small"
}

variable "key_pair_name" {
  type    = string
  default = ""
}

variable "allowed_ssh_cidrs" {
  type    = list(string)
  default = []
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.small"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}
