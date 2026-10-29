output "state_bucket_name" {
  description = "Nome do bucket de state."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN do bucket de state."
  value       = aws_s3_bucket.state.arn
}

output "role_arns" {
  description = "ARNs das roles do pipeline."
  value       = { for k, r in aws_iam_role.foundation : k => r.arn }
}

output "github_subs" {
  description = "Valores de sub aceitos por cada role."
  value       = local.github_subs
}