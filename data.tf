data "aws_ami" "centos-ami" {
  most_recent      = true
  name_regex       = "Centos-8-DevOps-Practice"
  owners           = ["973714476881"]
}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "mine" {
  name         = var.domain_name
}

data "aws_vpc" "default" {
  id = var.default_vpc_id
}