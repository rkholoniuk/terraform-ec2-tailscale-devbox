terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.44.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "terraform-aws-ec2"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  workload = "terraform-aws-ec2"
}

# VPC Module
module "vpc" {
  source     = "./modules/vpc"
  aws_region = var.aws_region
  workload   = local.workload
}

# RDS MySQL Module
module "rds_mysql" {
  count          = var.enable_rds ? 1 : 0
  source         = "./modules/mysql"
  workload       = local.workload
  vpc_id         = module.vpc.vpc_id
  subnets        = module.vpc.private_subnet_ids
  multi_az       = var.rds_multi_az
  instance_class = var.rds_instance_class
  username       = var.rds_username
  password       = var.rds_password
}

module "ssm" {
  source        = "./modules/ssm"
  workload      = local.workload
}

module "tailscale" {
  count         = 1
  source        = "./modules/tailscale"
  workload      = local.workload
  vpc_id        = module.vpc.vpc_id
  subnet        = module.vpc.private_subnet_ids[0]
  instance_type = "t4g.micro"
  ami           = "ami-0eac975a54dfee8cb" # Tailscale AMI for us-east-1
  userdata      = "ubuntu-tailscale-full.sh"
  depends_on = [module.ssm]
}

# DevBox EC2 Module
module "devbox" {
  source    = "./modules/devbox"
  workload  = local.workload
  vpc_id    = module.vpc.vpc_id
  az        = module.vpc.azs[0]
  subnet    = module.vpc.private_subnet_ids[0]
  allow_ssh = var.allow_ssh
}