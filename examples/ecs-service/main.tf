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

variable "enable_alb" {
  description = "Liga o ALB no plan (cobrado por hora numa conta real)."
  type        = bool
  default     = false
}

variable "enable_autoscaling" {
  description = "Liga o autoscaling por CPU no plan."
  type        = bool
  default     = false
}

module "network" {
  source = "../../modules/network"

  nome = "lab"
  azs  = ["us-east-1a", "us-east-1b"]

  tags = {
    Project = "terraform-aws-foundation"
  }
}

module "servico" {
  source = "../../modules/ecs-service"

  nome          = "lab-api"
  imagem        = "nginx:1.27"
  vpc_id        = module.network.vpc_id
  subnet_ids    = module.network.private_subnet_ids
  desired_count = 0

  enable_alb         = var.enable_alb
  alb_subnet_ids     = module.network.public_subnet_ids
  enable_autoscaling = var.enable_autoscaling

  tags = {
    Project = "terraform-aws-foundation"
  }
}

output "alb_dns_name" {
  value = module.servico.alb_dns_name
}