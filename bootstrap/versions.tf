terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Só será ativado quando o bucket existir de verdade (migração do state).
  # Neste modo estudo fica comentado.
  # backend "s3" {
  #   bucket       = "NOME-DO-BUCKET-DE-STATE"
  #   key          = "foundation/terraform.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}