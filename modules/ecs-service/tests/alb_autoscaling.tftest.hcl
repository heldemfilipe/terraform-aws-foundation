mock_provider "aws" {}

variables {
  nome       = "teste"
  imagem     = "nginx:1.27"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-aaaa1111", "subnet-bbbb2222"]
}

run "alb_vem_desligado_por_padrao" {
  command = plan

  assert {
    condition     = length(aws_lb.this) == 0 && length(aws_lb_target_group.this) == 0 && length(aws_lb_listener.http) == 0
    error_message = "O ALB não pode existir por padrão: cobra por hora."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.from_alb) == 0
    error_message = "Sem ALB, as tarefas não podem ter regra de entrada."
  }

  assert {
    condition     = length(aws_ecs_service.this.load_balancer) == 0
    error_message = "Sem ALB, o serviço não deve apontar para target group."
  }
}

run "alb_liga_por_variavel" {
  command = plan

  variables {
    enable_alb     = true
    alb_subnet_ids = ["subnet-pub1111", "subnet-pub2222"]
  }

  assert {
    condition     = length(aws_lb.this) == 1 && aws_lb.this[0].load_balancer_type == "application"
    error_message = "Com enable_alb = true deve existir um Application Load Balancer."
  }

  assert {
    condition     = aws_lb.this[0].drop_invalid_header_fields == true
    error_message = "O ALB deve descartar cabeçalhos HTTP inválidos."
  }

  assert {
    condition     = length(aws_ecs_service.this.load_balancer) == 1
    error_message = "O serviço deve apontar para o target group do ALB."
  }
}

run "tarefas_so_aceitam_trafego_do_alb_na_porta_do_conteiner" {
  command = plan

  variables {
    enable_alb     = true
    alb_subnet_ids = ["subnet-pub1111", "subnet-pub2222"]
    porta          = 9000
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.from_alb[0].from_port == 9000 && aws_vpc_security_group_ingress_rule.from_alb[0].to_port == 9000
    error_message = "A regra de entrada das tarefas deve usar a porta do contêiner."
  }
}

run "alb_usa_target_group_por_ip" {
  command = plan

  variables {
    enable_alb        = true
    alb_subnet_ids    = ["subnet-pub1111", "subnet-pub2222"]
    health_check_path = "/health"
  }

  assert {
    condition     = aws_lb_target_group.this[0].target_type == "ip"
    error_message = "Fargate com awsvpc exige target group do tipo ip."
  }

  assert {
    condition     = aws_lb_target_group.this[0].health_check[0].path == "/health"
    error_message = "O caminho de health check deve seguir a variável."
  }
}

run "alb_exige_duas_subnets" {
  command = plan

  variables {
    enable_alb     = true
    alb_subnet_ids = ["subnet-pub1111"]
  }

  expect_failures = [var.alb_subnet_ids]
}

run "autoscaling_vem_desligado_por_padrao" {
  command = plan

  assert {
    condition     = length(aws_appautoscaling_target.this) == 0 && length(aws_appautoscaling_policy.cpu) == 0
    error_message = "O autoscaling não pode existir por padrão."
  }
}

run "autoscaling_liga_por_variavel" {
  command = plan

  variables {
    enable_autoscaling = true
  }

  assert {
    condition     = aws_appautoscaling_target.this[0].min_capacity == 1 && aws_appautoscaling_target.this[0].max_capacity == 2
    error_message = "Os limites padrão do autoscaling devem ser 1 e 2."
  }

  assert {
    condition     = aws_appautoscaling_policy.cpu[0].target_tracking_scaling_policy_configuration[0].target_value == 60
    error_message = "A CPU alvo padrão deve ser 60%."
  }
}

run "maximo_menor_que_minimo_e_rejeitado" {
  command = plan

  variables {
    min_capacity = 3
    max_capacity = 2
  }

  expect_failures = [var.max_capacity]
}

run "cpu_alvo_fora_da_faixa_e_rejeitada" {
  command = plan

  variables {
    cpu_target_percent = 5
  }

  expect_failures = [var.cpu_target_percent]
}