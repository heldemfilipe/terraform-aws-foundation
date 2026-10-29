# secure-s3

Bucket S3 com as proteções básicas ligadas: criptografia, versionamento, bloqueio de
acesso público e política que nega tráfego sem TLS.

## Uso

```hcl
module "bucket" {
  source = "git::https://github.com/heldemfilipe/terraform-aws-foundation.git//modules/secure-s3?ref=v1.0.0"

  nome = "meu-bucket-unico"
}
```

Um exemplo completo está em [examples/secure-s3](../../examples/secure-s3).

## O que o módulo garante

| Proteção | Recurso | Impede |
|---|---|---|
| Criptografia em repouso (AES256) | `aws_s3_bucket_server_side_encryption_configuration` | Objetos sem criptografia no disco |
| Versionamento | `aws_s3_bucket_versioning` | Perda de dados por sobrescrita ou exclusão acidental |
| Bloqueio de acesso público (4 travas) | `aws_s3_bucket_public_access_block` | Bucket exposto por ACL ou política pública |
| Negação de acesso sem TLS | `aws_s3_bucket_policy` | Tráfego sem criptografia em trânsito |

## Decisões

- **Sem bloco `provider`.** Quem usa o módulo configura a AWS, o que permite testá-lo com provider simulado.
- **Sem consulta à conta (`aws_caller_identity`).** O nome do bucket vem por variável, o que mantém o módulo previsível no `plan`.
- **Política de TLS com `jsonencode`.** Ao contrário de `aws_iam_policy_document`, o resultado pode ser lido nos testes com `jsondecode`.
- **`force_destroy` desligado por padrão.** Apagar um bucket com dados exige escolha explícita.
- **Nome em português (`nome`).** Mantém a consistência com o restante do projeto.

## Testes

```bash
cd modules/secure-s3
terraform init -backend=false
terraform test
```

Os testes (`tests/protecao.tftest.hcl`) usam `mock_provider`, então não precisam de conta AWS:

| Teste | Modo | O que confere |
|---|---|---|
| `bloqueia_acesso_publico` | plan | As quatro travas de acesso público ligadas |
| `versiona_e_criptografa` | plan | Versionamento `Enabled` e algoritmo AES256 |
| `exige_tls` | apply simulado | A política nega acesso quando `aws:SecureTransport` é falso |
| `nome_invalido_e_rejeitado` | plan | Nomes fora do padrão do S3 são recusados |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.71.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Permite apagar o bucket mesmo com objetos dentro. | `bool` | `false` | no |
| <a name="input_nome"></a> [nome](#input\_nome) | Nome do bucket. Precisa ser único no mundo inteiro. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags aplicadas ao bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN do bucket. |
| <a name="output_id"></a> [id](#output\_id) | Nome (id) do bucket. |
<!-- END_TF_DOCS -->