variable "nome" {
  description = "Prefixo usado no nome dos recursos."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,30}$", var.nome))
    error_message = "Use de 2 a 30 caracteres: minúsculas, números e hífen."
  }
}

variable "cidr_block" {
  description = "Bloco CIDR da VPC. Precisa ser /20 ou maior, para caber as sub-redes /24."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0)) && tonumber(split("/", var.cidr_block)[1]) <= 20
    error_message = "Informe um CIDR válido com máscara /20 ou menor (por exemplo, 10.0.0.0/16)."
  }
}

variable "azs" {
  description = "Zonas de disponibilidade, uma sub-rede pública e uma privada em cada."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 1 && length(var.azs) <= 6
    error_message = "Informe de 1 a 6 zonas de disponibilidade."
  }
}

variable "enable_nat_gateway" {
  description = "Liga o NAT gateway (cobrado por hora). Desligado por padrão."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags aplicadas aos recursos."
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Tags extras só das sub-redes públicas (por exemplo, kubernetes.io/role/elb para o EKS). Name e Tier não podem ser sobrescritos."
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Tags extras só das sub-redes privadas (por exemplo, kubernetes.io/role/internal-elb para o EKS). Name e Tier não podem ser sobrescritos."
  type        = map(string)
  default     = {}
}