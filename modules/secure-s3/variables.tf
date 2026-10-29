variable "nome" {
  description = "Nome do bucket. Precisa ser único no mundo inteiro."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.nome))
    error_message = "O nome deve ter de 3 a 63 caracteres, só minúsculas, números, ponto e hífen."
  }
}

variable "force_destroy" {
  description = "Permite apagar o bucket mesmo com objetos dentro."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags aplicadas ao bucket."
  type        = map(string)
  default     = {}
}