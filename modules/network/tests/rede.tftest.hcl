mock_provider "aws" {}

variables {
  nome = "teste"
  azs  = ["us-east-1a", "us-east-1b"]
}

run "nat_vem_desligado_por_padrao" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_eip.nat) == 0
    error_message = "O NAT gateway e o IP elástico não podem existir por padrão: cobram por hora."
  }
}

run "nat_liga_por_variavel" {
  command = plan

  variables {
    enable_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1 && length(aws_eip.nat) == 1
    error_message = "Com enable_nat_gateway = true deve existir um NAT gateway e um IP elástico."
  }
}

run "uma_subrede_publica_e_privada_por_zona" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Deve haver uma sub-rede pública e uma privada por zona."
  }
}

run "cidrs_das_subredes_nao_colidem" {
  command = plan

  assert {
    condition     = aws_subnet.public["us-east-1a"].cidr_block == "10.0.0.0/24" && aws_subnet.private["us-east-1a"].cidr_block == "10.0.100.0/24"
    error_message = "Os CIDRs de sub-rede pública e privada devem ser 10.0.0.0/24 e 10.0.100.0/24 na primeira zona."
  }
}

run "subrede_publica_nao_atribui_ip_publico" {
  command = plan

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch == false])
    error_message = "As sub-redes públicas não devem atribuir IP público automaticamente."
  }
}

run "cidr_pequeno_demais_e_rejeitado" {
  command = plan

  variables {
    cidr_block = "10.0.0.0/28"
  }

  expect_failures = [var.cidr_block]
}

run "sem_zonas_e_rejeitado" {
  command = plan

  variables {
    azs = []
  }

  expect_failures = [var.azs]
}