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

module "bucket" {
  source = "../../modules/secure-s3"

  nome = "foundation-lab-exemplo-123456789012"

  tags = {
    Project = "terraform-aws-foundation"
  }
}

output "bucket_id" {
  value = module.bucket.id
}