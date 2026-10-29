terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Modo estudo: credenciais falsas, nada é criado na AWS.
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
}

variable "enable_nat" {
  description = "Liga o NAT gateway no plan (cobrado por hora numa conta real)."
  type        = bool
  default     = false
}

module "network" {
  source = "../../modules/network"

  nome               = "lab"
  azs                = ["us-east-1a", "us-east-1b"]
  enable_nat_gateway = var.enable_nat

  tags = {
    Project = "terraform-aws-foundation"
  }
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}