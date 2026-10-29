variable "nome" {
  description = "Nome do serviço. Prefixa os recursos."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,30}$", var.nome))
    error_message = "Use de 2 a 30 caracteres: minúsculas, números e hífen."
  }
}

variable "imagem" {
  description = "Imagem do contêiner, por exemplo nginx:1.27."
  type        = string

  validation {
    condition     = length(trimspace(var.imagem)) > 0
    error_message = "Informe a imagem do contêiner."
  }
}

variable "porta" {
  description = "Porta em que o contêiner escuta."
  type        = number
  default     = 8080

  validation {
    condition     = var.porta >= 1 && var.porta <= 65535
    error_message = "A porta precisa estar entre 1 e 65535."
  }
}

variable "cpu" {
  description = "CPU da tarefa Fargate, em unidades (256 = 0,25 vCPU)."
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "A CPU precisa ser 256, 512, 1024, 2048 ou 4096."
  }
}

variable "memoria" {
  description = "Memória da tarefa Fargate, em MiB."
  type        = number
  default     = 512

  validation {
    condition     = var.memoria >= 512
    error_message = "A memória mínima do Fargate é 512 MiB."
  }
}

variable "desired_count" {
  description = "Quantas tarefas manter rodando. Use 0 para não gastar nada."
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0
    error_message = "O número de tarefas não pode ser negativo."
  }
}

variable "region" {
  description = "Região usada na configuração de logs."
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID da VPC onde o serviço roda."
  type        = string
}

variable "subnet_ids" {
  description = "Sub-redes onde as tarefas rodam (use as privadas)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "Informe ao menos uma sub-rede."
  }
}

variable "environment" {
  description = "Variáveis de ambiente do contêiner."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Dias de retenção dos logs no CloudWatch."
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 180, 365], var.log_retention_days)
    error_message = "Use um valor aceito pelo CloudWatch: 1, 3, 5, 7, 14, 30, 60, 90, 180 ou 365."
  }
}

variable "task_policy_json" {
  description = "Política IAM (JSON) com as permissões que o aplicativo precisa. Sem ela, a task role não tem nenhuma."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags aplicadas aos recursos."
  type        = map(string)
  default     = {}
}

variable "enable_alb" {
  description = "Cria um Application Load Balancer na frente do serviço (cobrado por hora)."
  type        = bool
  default     = false
}

variable "alb_subnet_ids" {
  description = "Sub-redes públicas do ALB. Exige ao menos duas quando enable_alb = true."
  type        = list(string)
  default     = []

  validation {
    condition     = !var.enable_alb || length(var.alb_subnet_ids) >= 2
    error_message = "Com enable_alb = true, informe ao menos duas sub-redes em alb_subnet_ids."
  }
}

variable "alb_ingress_cidrs" {
  description = "Origens que podem acessar o ALB na porta 80."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for c in var.alb_ingress_cidrs : can(cidrhost(c, 0))])
    error_message = "Todos os valores de alb_ingress_cidrs precisam ser CIDRs válidos."
  }
}

variable "health_check_path" {
  description = "Caminho usado pelo ALB para checar a saúde das tarefas."
  type        = string
  default     = "/"
}

variable "enable_autoscaling" {
  description = "Liga o autoscaling por CPU."
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "Mínimo de tarefas com autoscaling."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Máximo de tarefas com autoscaling."
  type        = number
  default     = 2

  validation {
    condition     = var.max_capacity >= var.min_capacity
    error_message = "O máximo de tarefas não pode ser menor que o mínimo."
  }
}

variable "cpu_target_percent" {
  description = "CPU média alvo do autoscaling, em porcentagem."
  type        = number
  default     = 60

  validation {
    condition     = var.cpu_target_percent >= 10 && var.cpu_target_percent <= 90
    error_message = "A CPU alvo precisa estar entre 10 e 90."
  }
}