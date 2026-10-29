# Runbook: state travado e drift

> Escrito a partir dos experimentos em [06-experimentos.md](06-experimentos.md). O procedimento do lock no S3
> **nunca foi executado**: sem conta AWS, ele segue o comportamento documentado do Terraform.

## State travado

**Sintoma:** `plan` ou `apply` falha com `Error acquiring the state lock`, mostrando `Lock Info` com **ID**,
**Who**, **Created** e **Operation**. No backend S3 com `use_lockfile = true`, o lock é o objeto
`foundation/terraform.tfstate.tflock` ao lado do state.

**Por que existe:** impede dois processos de escreverem o state ao mesmo tempo. Quando um `apply` morre no meio
(runner cancelado, workflow interrompido), o objeto de lock pode ficar para trás.

### Passo a passo

1. **Descubra se a execução ainda está viva.** O lock só está "preso" se quem o criou não existe mais.

   ```bash
   gh run list --workflow apply --status in_progress
   gh run list --workflow plan --status in_progress
   gh run list --workflow drift --status in_progress
   ```

   Se houver uma execução em andamento, **espere**. Não destrave.

2. **Confira os dados do lock** (`Who` e `Created`). Seguro destravar quando **todas** forem verdade:
   - nenhuma execução do Actions está em andamento;
   - o `Created` é mais antigo que o apply mais longo que você já viu;
   - ninguém está rodando `terraform` à mão contra esse state.

3. **Destrave** com o ID da mensagem de erro, de uma máquina com credenciais de apply:

   ```bash
   cd envs/dev
   terraform init -backend-config="bucket=<STATE_BUCKET>" -backend-config="region=us-east-1"
   terraform force-unlock <LOCK_ID>
   ```

4. **Reavalie o estado.** Um apply interrompido pode ter criado recursos que o state não registrou. Rode
   `terraform plan`:
   - plan vazio: tudo bem, o apply tinha acabado de começar ou terminado;
   - quer **criar** algo que já existe na AWS: traga para o state com um bloco `import` (veja
     [06-experimentos.md](06-experimentos.md)) em vez de criar de novo.

### Quando NÃO destravar

- Há um apply em andamento, mesmo lento. **Dois escritores corrompem o state.**
- Você não sabe quem criou o lock. Descubra primeiro.

### Se o state foi corrompido

O bucket de state tem **versionamento ligado** (veja o [bootstrap](../bootstrap/state_bucket.tf)). Liste as versões
do objeto `foundation/terraform.tfstate`, restaure a anterior e rode `terraform plan` para conferir.

## Drift

**Sintoma:** o workflow [drift.yml](../.github/workflows/drift.yml) abriu (ou comentou numa) issue chamada
**Drift detectado**, com o plan completo. Isso significa que a AWS, o state e o código não batem.

O job roda todo dia às 06:00 (Brasília) com `terraform plan -detailed-exitcode`:

| Saída | Significado | O que o job faz |
|---|---|---|
| 0 | Plan vazio | Fecha a issue aberta, se houver |
| 1 | Erro (credencial, state travado, código inválido) | Falha o job; **investigue**, não é drift |
| 2 | Mudança pendente | Abre a issue (ou comenta na aberta) com o plan |

### Passo a passo

1. **Leia o plan da issue** e identifique o que mudou e **quem** mudou (CloudTrail, se tiver conta real).
2. **Antes de agir, descarte falso alarme.** Há um PR já mergeado esperando a aprovação do apply? Então o plan
   mostra o que falta aplicar, não drift.
3. **Decida o que vale:**

   | Situação | Ação |
   |---|---|
   | A mudança por fora foi **intencional** e deve ficar | Atualize o código para refletir. O plan fica vazio. PR normal |
   | A mudança por fora foi **indevida** | Reverta aplicando o código: rode de novo o último workflow `apply` (*Re-run all jobs*); ele gera um plan novo e pede a aprovação do environment |
   | Um recurso foi **criado por fora** | Importe com bloco `import` se deve ser gerenciado, ou apague se não deve existir |
   | Um recurso foi **apagado por fora** | O apply recria; confirme no plan antes |

4. **Confirme.** No dia seguinte o job vê o plan vazio e fecha a issue. Para não esperar, dispare à mão:

   ```bash
   gh workflow run drift
   ```

### Limites

- O drift só enxerga o que o Terraform gerencia. Recurso criado por fora que ele não conhece só aparece se o
  código tentar criar o mesmo.
- O plan lê a AWS com a role `foundation-drift`, de leitura. Ela não altera nada: corrigir o drift é sempre
  pelo pipeline de apply.
