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
    error_message = "O ID da conta precisa ter exatamente 12 dígitos."
  }
}

variable "github_repo" {
  description = "Repositório que pode assumir as roles, no formato dono/nome."
  type        = string
  default     = "heldemfilipe/terraform-aws-foundation"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.github_repo))
    error_message = "Use o formato dono/nome, sem espaços nem curingas."
  }
}

variable "github_environment" {
  description = "Environment do GitHub exigido para a role de apply."
  type        = string
  default     = "production"
}

variable "budget_email" {
  description = "E-mail que recebe os alertas de orçamento."
  type        = string

  validation {
    condition     = can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", var.budget_email))
    error_message = "Informe um e-mail válido."
  }
}

variable "monthly_budget_usd" {
  description = "Limite mensal do orçamento, em dólares."
  type        = number
  default     = 1

  validation {
    condition     = var.monthly_budget_usd > 0
    error_message = "O limite precisa ser maior que zero."
  }
}