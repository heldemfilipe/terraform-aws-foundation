# envs/dev

A pasta que o pipeline executa. Ela **usa** os módulos de [modules/](../../modules) e é o único lugar
onde `plan` e `apply` rodam pelo GitHub Actions.

Hoje contém só o [`secure-s3`](../../modules/secure-s3), de propósito: a role de apply só tem
permissão de S3 em `foundation-lab-*`. Um módulo novo aqui exige antes ampliar essa role no
[bootstrap](../../bootstrap/roles.tf).

| Detalhe | Valor |
|---|---|
| State | S3, chave `foundation/terraform.tfstate`, locking nativo (`use_lockfile`) |
| Backend | Configuração parcial: `bucket` e `region` entram no `terraform init -backend-config=...` |
| Nome do bucket | `foundation-lab-<account_id>-dev` (o prefixo é o que a role de apply pode criar) |

## Testar sem AWS

```bash
terraform init -backend=false
terraform validate
terraform test
```

Resultado esperado: `2 passed, 0 failed`. O `plan` não roda nesse modo porque o backend S3 não é
inicializado; ele é exercitado pelo pipeline.

O `.terraform.lock.hcl` vale para `linux_amd64`, `darwin_arm64` e `windows_amd64`, porque o CI roda em
Linux e o `init -lockfile=readonly` recusa um lock sem o checksum da plataforma. Para refazer:

```bash
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64
```
