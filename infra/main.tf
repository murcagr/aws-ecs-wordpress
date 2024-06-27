terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.47.0"
    }
  }
}

data "aws_availability_zones" "available" {}

locals {
  name           = "wordpress"
  vpc_cidr       = "10.0.0.0/16"
  azs            = slice(data.aws_availability_zones.available.names, 0, 3)
  http_port      = 80
  https_port     = 443
  container_port = 8080
  
  tags = {
    Name = local.name
  }
}

module "vpc" {
  source           = "terraform-aws-modules/vpc/aws"
  version          = "5.8.1"
  azs              = local.azs
  name             = "${var.app_name}-vpc"
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 8)]

  enable_nat_gateway = true
  # Just to save money
  single_nat_gateway = true


}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.7.0"

  identifier           = "${var.app_name}-db"
  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class       = var.db_instance_type

  allocated_storage = 10
  port = var.db_port
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [aws_security_group.db_local.id]

  enabled_cloudwatch_logs_exports = ["general"]
  create_cloudwatch_log_group     = true

  skip_final_snapshot         = true
  deletion_protection         = false
  manage_master_user_password = false
  username                    = var.db_user
  password                    = var.db_password
  db_name                     = var.db_name
}

resource "aws_security_group" "db_local" {
  vpc_id = module.vpc.vpc_id
  
  ingress {
    from_port        = var.db_port
    to_port          = var.db_port
    protocol         = "tcp"
    cidr_blocks      = [module.vpc.vpc_cidr_block]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}