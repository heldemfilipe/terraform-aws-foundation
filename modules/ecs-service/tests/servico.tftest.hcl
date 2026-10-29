mock_provider "aws" {}

variables {
  nome       = "teste"
  imagem     = "nginx:1.27"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-aaaa1111", "subnet-bbbb2222"]
}

run "mapeia_a_porta_do_conteiner" {
  command = plan

  assert {
    condition     = jsondecode(aws_ecs_task_definition.this.container_definitions)[0].portMappings[0].containerPort == 8080
    error_message = "A porta padrão do contêiner deve ser 8080."
  }
}

run "envia_logs_para_o_cloudwatch" {
  command = plan

  assert {
    condition     = jsondecode(aws_ecs_task_definition.this.container_definitions)[0].logConfiguration.logDriver == "awslogs"
    error_message = "O contêiner precisa enviar logs pelo driver awslogs."
  }

  assert {
    condition     = jsondecode(aws_ecs_task_definition.this.container_definitions)[0].logConfiguration.options["awslogs-group"] == "/ecs/teste"
    error_message = "O grupo de logs deve ser /ecs/<nome>."
  }
}

run "usa_fargate_com_awsvpc" {
  command = plan

  assert {
    condition     = contains(aws_ecs_task_definition.this.requires_compatibilities, "FARGATE") && aws_ecs_task_definition.this.network_mode == "awsvpc"
    error_message = "A tarefa precisa ser Fargate com rede awsvpc."
  }
}

run "tarefa_nao_recebe_ip_publico" {
  command = plan

  assert {
    condition     = aws_ecs_service.this.network_configuration[0].assign_public_ip == false
    error_message = "As tarefas não podem receber IP público."
  }
}

run "retencao_de_logs_padrao_e_7_dias" {
  command = plan

  assert {
    condition     = aws_cloudwatch_log_group.this.retention_in_days == 7
    error_message = "A retenção padrão de logs deve ser de 7 dias."
  }
}

run "roles_so_confiam_no_ecs" {
  command = plan

  assert {
    condition     = jsondecode(aws_iam_role.task.assume_role_policy).Statement[0].Principal.Service == "ecs-tasks.amazonaws.com"
    error_message = "A task role só pode ser assumida pelo serviço ecs-tasks."
  }

  assert {
    condition     = jsondecode(aws_iam_role.execution.assume_role_policy).Statement[0].Principal.Service == "ecs-tasks.amazonaws.com"
    error_message = "A execution role só pode ser assumida pelo serviço ecs-tasks."
  }
}

run "task_role_nasce_sem_permissoes" {
  command = plan

  assert {
    condition     = length(aws_iam_role_policy.task) == 0
    error_message = "Sem task_policy_json, a task role não pode ter nenhuma política."
  }
}

run "task_role_recebe_a_politica_informada" {
  command = plan

  variables {
    task_policy_json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::foundation-lab-exemplo/*\"}]}"
  }

  assert {
    condition     = length(aws_iam_role_policy.task) == 1
    error_message = "Com task_policy_json, deve existir uma política na task role."
  }
}

run "cpu_invalida_e_rejeitada" {
  command = plan

  variables {
    cpu = 300
  }

  expect_failures = [var.cpu]
}

run "imagem_vazia_e_rejeitada" {
  command = plan

  variables {
    imagem = ""
  }

  expect_failures = [var.imagem]
}

run "sem_subnets_e_rejeitado" {
  command = plan

  variables {
    subnet_ids = []
  }

  expect_failures = [var.subnet_ids]
}