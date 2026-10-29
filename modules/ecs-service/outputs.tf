output "cluster_name" {
  description = "Nome do cluster ECS."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "Nome do serviço ECS."
  value       = aws_ecs_service.this.name
}

output "security_group_id" {
  description = "ID do grupo de segurança das tarefas."
  value       = aws_security_group.service.id
}

output "task_role_arn" {
  description = "ARN da task role, para anexar permissões do aplicativo."
  value       = aws_iam_role.task.arn
}

output "log_group_name" {
  description = "Nome do grupo de logs no CloudWatch."
  value       = aws_cloudwatch_log_group.this.name
}

output "alb_dns_name" {
  description = "Endereço do ALB, ou null se enable_alb for false."
  value       = var.enable_alb ? aws_lb.this[0].dns_name : null
}