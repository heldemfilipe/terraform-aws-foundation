provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "terraform-aws-foundation"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

locals {
  # O prefixo foundation-lab- é o que a role de apply tem permissão de criar.
  bucket_name = "foundation-lab-${var.account_id}-dev"
}

module "bucket" {
  source = "../../modules/secure-s3"

  nome = local.bucket_name

  # A tag Project também vai explícita: a política da Etapa 5 lê tags do plan.
  tags = {
    Project = "terraform-aws-foundation"
  }
}