# Experimentos

Sem conta AWS, cada experimento foi reproduzido com o que dá para rodar localmente, **e o status diz exatamente
o que foi feito**. Os testes ficaram em pastas descartáveis, fora do repositório, com provedores locais
(`local`, `random` e o `terraform_data` embutido). Resultados de 2026-10-29, Terraform 1.17.1, Windows.

| Experimento | Status | Resultado observado |
|---|---|---|
| Drift | **Parcial**: lógica executada, AWS não | Detecção e passos do `drift.yml` testados localmente; alteração real pelo console da AWS **não executada** |
| Lock preso | **Não executado** | A tentativa local não reproduz; só vale no S3 |
| Refatoração sem recriar (`moved`) | **Executado** (local) | Sem `moved`: 1 a criar, 1 a destruir. Com `moved`: 0 a criar, 0 a destruir |
| Recurso criado fora (`import`) | **Executado** (local) | `1 to import, 0 to add, 0 to destroy`; com atributo errado, o Terraform recriou |
| Fork malicioso | **Parcial** | A trust policy só aceita os `sub` previstos (teste passa); PR de fork real **não executado** |

## Drift

**Montagem:** um `local_file` aplicado; depois o arquivo foi alterado por fora, o equivalente a mexer numa tag pelo
console.

| Situação | `terraform plan -detailed-exitcode` |
|---|---|
| Nada mudou | saída **0** |
| Arquivo alterado por fora | saída **2** (o plan quer recriar o arquivo) |
| Erro na configuração (`resource "local_file" "x" {}` sem argumentos) | saída **1** |

Os três códigos são os que o roteiro e o [runbook](05-runbook.md) assumem.

**O passo do workflow** (`gh` e `terraform` simulados) foi executado nos cinco caminhos:

| Entrada | Resultado |
|---|---|
| Saída 0, sem issue aberta | Nada acontece |
| Saída 0, issue aberta | `gh issue close` |
| Saída 2, sem issue aberta | `gh label create`, depois `gh issue create` |
| Saída 2, issue aberta | `gh issue comment` (não duplica a issue) |
| Saída 1 | O passo falha com a mesma saída |

**Não executado:** a detecção com recursos da AWS (a role `foundation-drift`, o OIDC no job agendado e a criação
da issue no GitHub).

## Lock preso

**Tentativa:** `apply` com um `local-exec` lento, processo do `terraform` morto no meio, depois um `plan`.

**Observado:** o `plan` seguinte **funcionou normalmente**. No backend local do Windows, o lock é do sistema
operacional e some quando o processo morre; o Terraform ainda limpou o arquivo `.terraform.tfstate.lock.info`.
O experimento **não reproduz** o lock do S3, que é um objeto `.tflock` e fica até alguém apagá-lo.

**Por isso** o procedimento do [runbook](05-runbook.md) segue o comportamento documentado do Terraform e não foi
verificado na prática.

## Refatoração sem recriar (`moved`)

**Montagem:** um `terraform_data.bucket` aplicado; depois renomeado para `terraform_data.armazenamento`.

| Estado do código | Plan |
|---|---|
| Só renomeado | `Plan: 1 to add, 0 to change, 1 to destroy` (o antigo some, o novo é criado) |
| Renomeado **e** com o bloco abaixo | `terraform_data.bucket has moved to terraform_data.armazenamento`, `Plan: 0 to add, 0 to change, 0 to destroy` |

```hcl
moved {
  from = terraform_data.bucket
  to   = terraform_data.armazenamento
}
```

O `apply` seguinte só atualizou o state e `terraform state list` mostrou o recurso com o nome novo.

**Para este projeto:** mudar o nome do recurso dentro de um módulo (por exemplo `this`) ou mover um módulo
destruiria e recriaria o recurso real. Quem consome o módulo por tag precisa do `moved` no mesmo release.

## Recurso criado fora (`import`)

**Montagem:** um `random_id` já "existente" (id conhecido), e o Terraform não o conhece.

```hcl
import {
  to = random_id.existente
  id = "Zm91bmRhdGlvbi1sYWI"
}
```

| Tentativa | Plan |
|---|---|
| Configuração com `byte_length = 15` (diferente do real) | `must be replaced`: `1 to import, 1 to add, 0 to change, 1 to destroy` |
| Configuração com `byte_length = 14` (igual ao real) | `will be imported`: `1 to import, 0 to add, 0 to change, 0 to destroy` |

Depois do `apply`, o `plan` seguinte deu `No changes`.

**Lição:** o `import` só evita a recriação se o **código descrever o recurso como ele já é**. Se a configuração
diverge, o Terraform importa e em seguida planeja substituí-lo. Por isso o passo a passo é sempre: escrever o
recurso, rodar o `plan` e só aplicar quando ele disser `to import` sem `destroy`.

## Fork malicioso

**Montagem esperada:** um PR de um fork tenta executar o apply.

**Não executado.** O que está verificado é só o que impede isso:

- a role de apply só aceita o `sub` `repo:heldemfilipe/terraform-aws-foundation:environment:production`, e o teste
  [trust.tftest.hcl](../bootstrap/tests/trust.tftest.hcl) confirma que não há curinga e que plan e apply usam
  `sub` diferentes;
- o GitHub não entrega o token OIDC a PRs de forks, então o `plan.yml` nem consegue assumir a role de plan.

O que **não** está verificado é o comportamento real da AWS e do GitHub negando um fork.
