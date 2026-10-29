output "vpc_id" {
  description = "ID da VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs das sub-redes públicas, na ordem das zonas."
  value       = [for az in var.azs : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "IDs das sub-redes privadas, na ordem das zonas."
  value       = [for az in var.azs : aws_subnet.private[az].id]
}

output "nat_gateway_enabled" {
  description = "Indica se o NAT gateway foi criado."
  value       = var.enable_nat_gateway
}