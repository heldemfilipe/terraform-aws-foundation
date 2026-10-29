output "id" {
  description = "Nome (id) do bucket."
  value       = aws_s3_bucket.this.id
}

output "arn" {
  description = "ARN do bucket."
  value       = aws_s3_bucket.this.arn
}