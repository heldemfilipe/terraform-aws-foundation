# --- Grupo de segurança do ALB ---

resource "aws_security_group" "alb" {
  count = var.enable_alb ? 1 : 0

  name        = "${var.nome}-alb"
  description = "ALB do servico ${var.nome}"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.nome}-alb" })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = var.enable_alb ? toset(var.alb_ingress_cidrs) : toset([])

  security_group_id = aws_security_group.alb[0].id
  description       = "HTTP de ${each.value}"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_para_tarefas" {
  count = var.enable_alb ? 1 : 0

  security_group_id            = aws_security_group.alb[0].id
  description                  = "ALB para as tarefas"
  ip_protocol                  = "tcp"
  from_port                    = var.porta
  to_port                      = var.porta
  referenced_security_group_id = aws_security_group.service.id
}

# As tarefas só aceitam tráfego vindo do ALB.
resource "aws_vpc_security_group_ingress_rule" "from_alb" {
  count = var.enable_alb ? 1 : 0

  security_group_id            = aws_security_group.service.id
  description                  = "Trafego vindo do ALB"
  ip_protocol                  = "tcp"
  from_port                    = var.porta
  to_port                      = var.porta
  referenced_security_group_id = aws_security_group.alb[0].id
}

# --- Balanceador ---

#trivy:ignore:AWS-0053
resource "aws_lb" "this" {
  count = var.enable_alb ? 1 : 0

  name                       = var.nome
  load_balancer_type         = "application"
  internal                   = false
  subnets                    = var.alb_subnet_ids
  security_groups            = [aws_security_group.alb[0].id]
  drop_invalid_header_fields = true
  tags                       = var.tags
}

resource "aws_lb_target_group" "this" {
  count = var.enable_alb ? 1 : 0

  name        = var.nome
  port        = var.porta
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  tags        = var.tags

  health_check {
    path    = var.health_check_path
    matcher = "200-399"
  }
}

#trivy:ignore:AWS-0054
resource "aws_lb_listener" "http" {
  count = var.enable_alb ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"
  tags              = var.tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }
}