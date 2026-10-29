provider "aws" {
  region = var.region

  # Modo estudo: nada é aplicado. Credenciais falsas e sem checagens na AWS.
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
}