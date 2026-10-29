variable "region" {
  description = "Região da AWS."
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "ID da conta AWS (12 dígitos). Entra no nome do bucket."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id precisa ter exatamente 12 dígitos."
  }
}