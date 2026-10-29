locals {
  # jsonencode em vez de aws_iam_policy_document: com mock_provider, data sources
  # voltam com valores aleatórios, e o JSON da política precisa ser real para ser testado.
  ecs_tasks_trust = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# --- Logs ---

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.nome}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# --- Cluster ---

resource "aws_ecs_cluster" "this" {
  name = var.nome
  tags = var.tags

  # Container Insights cobra à parte; fica desligado.
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

# --- Roles ---

# Execution role: o ECS usa para puxar a imagem e escrever logs.
resource "aws_iam_role" "execution" {
  name               = "${var.nome}-execution"
  assume_role_policy = local.ecs_tasks_trust
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role: o aplicativo usa. Começa sem nenhuma permissão.
resource "aws_iam_role" "task" {
  name               = "${var.nome}-task"
  assume_role_policy = local.ecs_tasks_trust
  tags               = var.tags
}

resource "aws_iam_role_policy" "task" {
  count = var.task_policy_json == null ? 0 : 1

  name   = "app"
  role   = aws_iam_role.task.id
  policy = var.task_policy_json
}

# --- Tarefa ---

resource "aws_ecs_task_definition" "this" {
  family                   = var.nome
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memoria
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  tags                     = var.tags

  container_definitions = jsonencode([{
    name      = var.nome
    image     = var.imagem
    essential = true

    portMappings = [{ containerPort = var.porta, protocol = "tcp" }]
    environment  = [for k, v in var.environment : { name = k, value = v }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = var.nome
      }
    }
  }])
}

# --- Rede: nenhuma entrada; saída só HTTPS (imagem e logs) ---

resource "aws_security_group" "service" {
  name        = "${var.nome}-service"
  description = "Tarefas do servico ${var.nome}"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.nome}-service" })
}

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.service.id
  description       = "HTTPS para puxar a imagem e enviar logs"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# --- Serviço ---

resource "aws_ecs_service" "this" {
  name            = var.nome
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  tags            = var.tags

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.enable_alb ? [1] : []

    content {
      target_group_arn = aws_lb_target_group.this[0].arn
      container_name   = var.nome
      container_port   = var.porta
    }
  }

  # O serviço só pode apontar para o target group depois que o listener existir.
  depends_on = [aws_lb_listener.http]

  # Com autoscaling, quem controla o número de tarefas é ele, não o Terraform.
  lifecycle {
    ignore_changes = [desired_count]
  }
}
