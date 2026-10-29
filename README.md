# terraform-aws-foundation

Módulos Terraform para AWS, com pipeline plan/apply, policy as code e detecção de drift.

> **Status:** projeto de estudo, em construção. **Nunca foi aplicado na AWS**: tudo é validado
> com `terraform validate`, `terraform test` (mock provider), `terraform plan` offline e
> políticas em Rego.

## Problema

_A preencher: por que uma fundação de IaC com módulos pequenos, testados e versionados._

## Arquitetura

_A preencher: diagrama Mermaid gerado com `terraform graph -format=mermaid` (Etapa 2)._

```
bootstrap/    bucket de state, provedor OIDC e roles (state local, uma única vez)
modules/      network, secure-s3 e ecs-service
examples/     um exemplo de uso por módulo
policy/       políticas em Rego (OPA/conftest)
.github/      workflows de plan, apply e drift
docs/         guias e runbook
```

## Como usar cada módulo

_A preencher a cada módulo (Etapa 2), com o trecho gerado pelo terraform-docs._

## Decisões

| Peça | Escolha | Motivo |
|---|---|---|
| Terraform ou OpenTofu | _a decidir_ | _escrever o motivo_ |
| State | S3 com `use_lockfile = true` | Locking nativo, sem DynamoDB |
| Identidade do pipeline | GitHub Actions com OIDC | Sem chave de acesso de longa duração |
| Segurança | _Trivy ou Checkov_ | _escrever o motivo_ |
| Policy as code | OPA com conftest | Bloqueia o PR com mensagem legível |
| Role de plan | `ReadOnlyAccess` mais acesso ao state e só escrita do `.tflock` | Simplificação de estudo: lê mais do que precisa; um projeto real restringiria |
| Role de apply | Permissões estreitas, só buckets `foundation-lab-*` e o state; nunca `AdministratorAccess` | Limita o dano se o pipeline for comprometido |
| Aprovação do apply | Environment `production` com revisor obrigatório | O `sub` da role de apply exige esse environment; ninguém aplica de outra branch ou fork |
| Teste da trust policy | `terraform test` com `mock_provider` sobre o output `github_subs` | Sem AWS não dá para ver a AWS negar; o teste prova que só os `sub` certos são gerados e que valores com curinga são recusados |

## Custo

Custo real: zero, porque nada é aplicado. _A preencher: estimativa de custo dos módulos com
Infracost (Etapa 5, opcional)._ Como rodar sem AWS em [docs/00-instalacao.md](docs/00-instalacao.md).

## Experimentos

| Experimento | Status | Resultado observado |
|---|---|---|
| Drift | não executado | |
| Lock preso | não executado | |
| Refatoração sem recriar (`moved`) | não executado | |
| Recurso criado fora (`import`) | não executado | |
| Fork malicioso | não executado | |

## Etapas

- [x] Etapa 0: repositório e estrutura
- [x] Etapa 1: state remoto e identidade (só código: validado e testado, não aplicado)
- [ ] Etapa 2: módulos reutilizáveis
- [ ] Etapa 3: qualidade local
- [ ] Etapa 4: pipeline de plan e apply
- [ ] Etapa 5: policy as code e custo
- [ ] Etapa 6: drift e recuperação

## Licença

MIT. Veja [LICENSE](LICENSE).
