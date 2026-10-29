mock_provider "aws" {}

variables {
  nome = "bucket-de-teste"
}

run "bloqueia_acesso_publico" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == true
    error_message = "O bucket precisa bloquear ACLs públicas."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.this.block_public_policy,
      aws_s3_bucket_public_access_block.this.ignore_public_acls,
      aws_s3_bucket_public_access_block.this.restrict_public_buckets,
    ])
    error_message = "Todas as quatro travas de acesso público precisam estar ligadas."
  }
}

run "versiona_e_criptografa" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "O versionamento precisa estar ligado."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "O bucket precisa ser criptografado."
  }
}

run "exige_tls" {
  command = apply

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.this.policy).Statement[0].Effect == "Deny"
    error_message = "A política precisa negar acesso sem TLS."
  }

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.this.policy).Statement[0].Condition.Bool["aws:SecureTransport"] == "false"
    error_message = "A condição precisa ser aws:SecureTransport igual a false."
  }
}

run "nome_invalido_e_rejeitado" {
  command = plan

  variables {
    nome = "Nome_Invalido"
  }

  expect_failures = [var.nome]
}