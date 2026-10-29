# 01 - Consumindo os módulos por tag

Os módulos são versionados com tags do git. Quem os usa fixa a versão no `source`, e uma
mudança nova no repositório não afeta quem está numa tag antiga.

## Formato do `source`

```hcl
module "network" {
  source = "git::https://github.com/heldemfilipe/terraform-aws-foundation.git//modules/network?ref=v1.0.0"

  nome = "lab"
  azs  = ["us-east-1a", "us-east-1b"]
}
```

| Parte | Significado |
|---|---|
| `git::https://...foundation.git` | Clona o repositório inteiro |
| `//modules/network` | Usa só esta subpasta (a barra dupla é obrigatória) |
| `?ref=v1.0.0` | Fixa a tag. Sem `ref`, o Terraform usaria a branch padrão, que muda |

## Teste feito sem enviar nada ao GitHub

O consumidor de teste (um projeto separado, fora deste repositório) aponta o `source` para a pasta
local, que tem a tag `v1.0.0`:

```hcl
source = "git::file:///D:/Projetos/Estudo/Terraform/terraform-aws-foundation//modules/network?ref=v1.0.0"
```

Resultado observado, com credenciais falsas e sem criar nada na AWS:

| Comando | Resultado |
|---|---|
| `terraform init -backend=false` | Baixou os dois módulos pela tag `v1.0.0` |
| `terraform validate` | `Success! The configuration is valid.` |
| `terraform plan` | `Plan: 22 to add, 0 to change, 0 to destroy` |

O `plan` é idêntico ao de `examples/ecs-service`, o que confirma que o módulo funciona fora deste
repositório. No GitHub, basta trocar o `file:///...` pela URL `https://` acima.

## Versionamento

- `v1.0.0` marca os três módulos da Etapa 2.
- Uma tag não deve ser movida depois de publicada. Mudanças futuras ganham uma versão nova
  (`v1.1.0` para novidade compatível, `v2.0.0` para mudança que quebra quem usa).
- O roteiro cita `v1.0.0` de novo no fim do projeto (Etapa 6). Como essa tag já existe, o
  fechamento do projeto usa a próxima versão disponível.
