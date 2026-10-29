# 00 - Instalação e preparo (Etapa 0)

Guia para deixar a máquina pronta antes de escrever a primeira linha de Terraform.
Sistema: Windows 11. Use o **PowerShell como administrador** nos passos que
instalam programas (botão direito no PowerShell, "Executar como administrador").

Depois de instalar qualquer coisa, **feche e abra o terminal** para o PATH atualizar.

## 1. O que cada ferramenta faz

| Ferramenta | Para que serve neste projeto | Etapa |
|---|---|---|
| Terraform | Lê os arquivos `.tf` e cria/atualiza a infraestrutura | todas |
| AWS CLI | Conversa com a AWS pelo terminal e guarda o seu login | 1 |
| gh (GitHub CLI) | Login no GitHub e comandos do repositório pelo terminal | 0 |
| tflint | Aponta erros e más práticas no código Terraform | 3 |
| terraform-docs | Gera a tabela de variáveis e outputs do README de cada módulo | 2 |
| pre-commit | Roda as checagens automaticamente a cada `git commit` | 3 |
| gitleaks | Impede que uma senha ou chave vá para o commit | 3 |
| Trivy | Procura configurações inseguras no Terraform | 3 |
| conftest | Aplica as suas regras (policy as code) sobre o plan | 5 |
| opa | Roda os testes das suas regras escritas em Rego | 5 |
| Infracost | Estima o custo de cada mudança (opcional) | 5 |

## 2. Atualizar o Terraform

A máquina tinha o Terraform 1.9.3, copiado à mão para `C:\variaveis`. O projeto usa
`use_lockfile` no state do S3, que só existe a partir da 1.10. O roteiro pede a série 1.16.

```powershell
choco install terraform -y
```

A cópia antiga pode continuar na frente no PATH. Renomeie para ela sair do caminho:

```powershell
Rename-Item C:\variaveis\terraform.exe terraform-1.9.3.exe.bak
```

Feche e abra o terminal e confira:

```powershell
terraform version
```

Deve mostrar 1.10 ou mais. Para o `terraform graph -format=mermaid` da Etapa 2 é preciso 1.16.

## 3. Demais ferramentas

```powershell
choco install tflint terraform-docs gitleaks trivy -y
```

```powershell
winget install GitHub.cli
```

```powershell
pip install pre-commit
```

`opa` (Etapa 5) vem do winget:

```powershell
winget install open-policy-agent.opa
```

O `conftest` não está no choco nem no winget. Baixe o `.zip` Windows da página de releases
(open-policy-agent/conftest), **confira o checksum** contra o `checksums.txt` da mesma página e copie o
`conftest.exe` para uma pasta do PATH. O passo a passo com os comandos está em
[docs/04-policy-as-code.md](04-policy-as-code.md).

Login no GitHub (escolha HTTPS e siga o navegador):

```powershell
gh auth login
```

## 4. Conferir tudo

```powershell
foreach ($c in 'terraform','aws','gh','tflint','terraform-docs','pre-commit','gitleaks','trivy','conftest','opa') { $p = Get-Command $c -ErrorAction SilentlyContinue; if ($p) { "$c OK" } else { "$c FALTA" } }
```

Na Etapa 0 só precisam estar OK: terraform, gh, tflint, terraform-docs, pre-commit e gitleaks.
O `aws` pode ficar sem credenciais neste modo estudo.
`trivy` é da Etapa 3 e `conftest`/`opa` da Etapa 5.

## 5. Modo estudo: sem conta AWS e sem `apply`

Este projeto é feito **sem aplicar nada na AWS**. Você não precisa de conta, de `aws login`
nem de cartão. A regra é uma só: **nunca rode `terraform apply`** (nem `-migrate-state`).

| Roda normalmente (custo zero) | Não roda neste modo |
|---|---|
| `terraform init -backend=false` | `terraform apply` e `destroy` |
| `terraform fmt` e `terraform validate` | Migrar o state para o S3 |
| `terraform test` com `mock_provider` (plan e apply simulados) | Assumir a role pelo OIDC de verdade |
| `terraform plan` com credencial falsa (veja abaixo) | Workflows `plan.yml`, `apply.yml` e `drift.yml` executando |
| `terraform show -json`, conftest, `opa test` | Os experimentos de drift, lock preso e import |
| tflint, Trivy, gitleaks, pre-commit | |

### 5.1 `terraform plan` sem AWS

O provider da AWS tenta validar credenciais ao planejar. Nos `examples/`, e **nunca dentro de
`modules/`**, use credenciais falsas e desligue essas checagens:

```hcl
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
}
```

Como não há AWS para responder, os módulos **não podem usar `data "aws_caller_identity"` nem
`data "aws_availability_zones"`**. Receba o ID da conta e as zonas por variável.

Comandos de cada exemplo (na pasta dele):

```powershell
terraform init -backend=false
```

```powershell
terraform plan -out=plan.tfplan
```

```powershell
terraform show -json plan.tfplan > plan.json
```

O `plan.json` é a entrada do conftest na Etapa 5. `*.tfplan` e `plan.json` estão no `.gitignore`.

### 5.2 Como o repositório conta a história

Escreva no README que é um projeto de estudo **nunca aplicado na AWS**, e deixe a coluna
"Status" dos experimentos como `não executado`. A evidência do projeto é o que roda de verdade:
módulos testados, políticas em Rego com testes, pre-commit e CI verde.

## 6. (Opcional) Se um dia usar a AWS de verdade

Só se tiver uma conta com crédito ou custo aceitável. Use a AWS com travas, porque um recurso
esquecido ligado vira cobrança. Leia a lista de regras antes de rodar qualquer `apply`.

### 6.1 Acesso seguro

1. Tenha uma conta AWS e ative **MFA** no usuário raiz.
2. Não use o usuário raiz no dia a dia. Crie um acesso para você pelo IAM Identity Center
   (ou, se preferir, um usuário IAM com MFA) e use esse acesso no terminal.
3. Entre pelo terminal. O seu AWS CLI sugere `aws login`; a alternativa é `aws configure sso`:

```powershell
aws login
```

4. Confirme quem você é. Isto não cria nada e não custa nada:

```powershell
aws sts get-caller-identity
```

### 6.2 Orçamento antes de tudo

No console, em Billing, **Budgets**, crie um orçamento mensal baixo (por exemplo US$ 1) com
alerta por e-mail em 80% do valor. A Etapa 1 também cria um por Terraform. Os dois primeiros
orçamentos costumam ser gratuitos; confirme na página de preços do AWS Budgets.

### 6.3 Regras de custo zero

| Pode aplicar | Por quê |
|---|---|
| Bucket S3 de state, `secure-s3` | Poucos KB armazenados custam centavos ou nada |
| Provedor OIDC e roles IAM | IAM não é cobrado |
| VPC, sub-redes, tabelas de rota | Não são cobradas |
| ECS cluster e service com `desired_count = 0` | Cluster não é cobrado, e sem tarefa rodando não há Fargate |

| NÃO aplique | Por quê |
|---|---|
| NAT gateway (`network` com NAT ligado) | Cobra por hora, mesmo sem tráfego |
| ALB (`ecs-service` com load balancer) | Cobra por hora |
| ECS service com tarefas rodando | Fargate cobra por segundo de CPU e memória |
| Qualquer IP público elástico parado | IPv4 público é cobrado por hora |

Hábitos:

- Cada `terraform plan` é gratuito; só o `apply` cria coisas.
- Termine toda sessão de teste com `terraform destroy` e confira o console.
- Uma vez por semana abra Billing, **Cost Explorer**, e veja se há algo inesperado.
- Bucket com versionamento precisa de `force_destroy = true` (ou esvaziar as versões) para o
  `destroy` funcionar. Decida isso ao escrever o bootstrap.
