# Configure the AWS Provider
provider "aws" {
  region     = "us-east-1"
  access_key = 
  secret_key = 
}

locals {
  region = "us-east-1"
  tags = {
    Name = "module_vpc"
    Env = "dev"
    Owner = "vv"
  }
}


################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = local.tags
}