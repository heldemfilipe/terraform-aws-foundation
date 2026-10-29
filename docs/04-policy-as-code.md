# Policy as code e custo (Etapa 5)

> **Status:** as políticas foram testadas localmente com `opa` e `conftest`. Os workflows que as rodam no PR
> (`plan.yml`, `cost.yml`) foram validados com `actionlint` e **nunca executados**.

## A ideia

O `plan` mostra o que vai mudar; a política decide se pode. O fluxo é:

```
terraform plan -out=plan.tfplan  →  terraform show -json  →  plan.json  →  conftest test  →  deny?
```

Cada regra `deny` escrita em Rego que dispara vira uma mensagem de erro, e o check `plan` do PR fica vermelho.

## As políticas

Em [policy/](../policy), todas em `package main`:

| Arquivo | Regra | Mensagem |
|---|---|---|
| [tags.rego](../policy/tags.rego) | Todo recurso criado que aceita tags precisa de `Project` e `Environment` | `<recurso> precisa da tag <tag>` |
| [s3.rego](../policy/s3.rego) | Todo bucket criado precisa de criptografia no mesmo módulo | `<bucket> precisa de criptografia (...)` |
| [s3.rego](../policy/s3.rego) | Todo bucket criado precisa do bloqueio de acesso público com as quatro travas ligadas | `<bucket> precisa do bloqueio total de acesso público (...)` |
| [security_group.rego](../policy/security_group.rego) | Nenhuma regra de entrada abre 22 ou 3389 (ou todo o tráfego) para `0.0.0.0/0` ou `::/0` | `<regra> expõe porta administrativa para <rede>` |

Quatro regras em três arquivos: o roteiro pede três políticas, e a de bucket se divide em duas porque o
critério de conclusão fala também em bucket **público**.

### Decisões e limites

- **Tags pelo `tags_all`.** Ele inclui as `default_tags` do provider, que é o que de fato vai para o recurso.
  Um recurso sem tags e sem `default_tags` aparece no plan com `tags: null` e `tags_all` ausente (desconhecida
  até o apply); a política trata esse caso como "sem tag nenhuma".
- **Criptografia e bloqueio público por módulo.** No plan, esses recursos não ligam ao bucket por referência.
  A política confere se existem **no mesmo módulo** do bucket. É uma heurística: falharia com dois buckets no
  mesmo módulo.
- **Security group.** Cobre `aws_vpc_security_group_ingress_rule` e o bloco `ingress` de `aws_security_group`.
  Não cobre `aws_security_group_rule` nem regras de saída.
- **Só `create`.** Recursos que já existem e só mudam não são avaliados.

## Os testes

```bash
opa test policy/ -v
```

São 17 testes em [policy/policy_test.rego](../policy/policy_test.rego). Cada um monta um plan mínimo no formato
do `terraform show -json` e confere as mensagens exatas (casos que passam e casos que falham).

Além disso, dois planos **reais** em [testdata/](../testdata), gerados pelo Terraform:

```bash
conftest test testdata/plan-ok.json --policy policy/      # 0 falhas
conftest test testdata/plan-ruim.json --policy policy/    # 10 falhas
```

O `plan-ok.json` é o plan do `envs/dev`. O `plan-ruim.json` tem um bucket sem tags, criptografia e bloqueio
público, um security group com SSH aberto e uma regra de RDP aberta.

> Os planos de exemplo **não ficam dentro de `policy/`**: o `opa test` carrega todo JSON da pasta como dado e
> falha com `merge error` ao fundir dois arquivos no mesmo caminho.

Para regenerar um plan sem AWS, a partir de uma pasta com provider de credenciais falsas (como os exemplos):

```bash
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan > plan.json
```

## No pipeline

O [plan.yml](../.github/workflows/plan.yml) passa a fazer, depois do `plan`:

1. `terraform show -json plan.tfplan > plan.json`.
2. Instala o `conftest` v0.71.1, com **checksum SHA-256 fixo** conferido antes de instalar.
3. `conftest verify`: roda os testes das políticas.
4. `conftest test`: avalia o plan; o resultado vai para um arquivo e o código de saída é guardado.
5. Comenta no PR o plan **e** o resultado das políticas (`aprovado` ou `BLOQUEADO`).
6. Se alguma política falhou, o último passo derruba o job. O check `plan` fica vermelho e, com a proteção da
   `main` do [docs/03-pipeline.md](03-pipeline.md), o merge é bloqueado.

O comentário sai mesmo com violação: é ele que explica o motivo do bloqueio.

## Custo com Infracost (opcional)

O [cost.yml](../.github/workflows/cost.yml) estima, em cada PR que mexe em `modules/` ou `examples/`, o custo do
`network` com NAT e do `ecs-service` com ALB, os dois cenários que cobram, e comenta no PR. Os exemplos usam
credenciais falsas, então a estimativa não precisa de acesso à AWS.

Para ativar:

1. Instale o Infracost e rode `infracost auth login` para obter uma chave gratuita.
2. Guarde em *Settings → Secrets and variables → Actions → Secrets* com o nome `INFRACOST_API_KEY`. Esta é uma
   **secret** de verdade, ao contrário das variáveis do pipeline.

**Não executado:** as opções de linha de comando (`--terraform-var`, `--behavior update`) seguem a documentação
do Infracost, mas não foram testadas aqui. PRs de forks não recebem secrets, então o job falha neles.

## Instalar as ferramentas no Windows

```powershell
winget install open-policy-agent.opa
```

O `conftest` não está no choco nem no winget. Baixe, confira o checksum e instale:

```powershell
$v = "0.71.1"
$dir = "$env:TEMP\conftest"
New-Item -ItemType Directory -Force $dir | Out-Null
$zip = "conftest_${v}_Windows_x86_64.zip"
$base = "https://github.com/open-policy-agent/conftest/releases/download/v$v"
Invoke-WebRequest "$base/$zip" -OutFile "$dir\$zip"
Invoke-WebRequest "$base/checksums.txt" -OutFile "$dir\checksums.txt"
$esperado = ((Select-String -Path "$dir\checksums.txt" -Pattern $zip -SimpleMatch).Line -split '\s+')[0]
$real = (Get-FileHash "$dir\$zip" -Algorithm SHA256).Hash
if ($esperado -ieq $real) {
  Expand-Archive "$dir\$zip" -DestinationPath $dir -Force
  Copy-Item "$dir\conftest.exe" "C:\variaveis\conftest.exe"
  "checksum ok, instalado"
} else { "CHECKSUM DIFERENTE: nao instale"; $esperado; $real }
```
