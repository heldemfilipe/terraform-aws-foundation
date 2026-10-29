# Qualidade local (Etapa 3)

Três verificações rodam no seu computador antes de qualquer commit chegar ao GitHub. Nenhuma
precisa de conta AWS.

| Bloco | Ferramenta | O que impede |
|---|---|---|
| Formato e validade | `terraform fmt` e `terraform validate` | Código mal formatado ou inválido |
| Estilo e boas práticas | `tflint` (regras do Terraform e da AWS) | Variável sem tipo, variável não usada, argumento inválido para a AWS |
| Segredos | `gitleaks` | Token ou chave de acesso indo para o histórico |
| Documentação | `terraform-docs` | README dos módulos desatualizado em relação ao código |
| Segurança da configuração | `trivy config` | Recurso criado de forma insegura (roda à parte, veja abaixo) |

## Configuração

- [.pre-commit-config.yaml](../.pre-commit-config.yaml) liga os hooks do `pre-commit`.
- [.tflint.hcl](../.tflint.hcl) ativa o preset `recommended` do Terraform e o plugin da AWS.

```bash
pre-commit install          # uma vez; passa a rodar a cada git commit
tflint --init               # uma vez; baixa o plugin da AWS
pre-commit run --all-files  # roda tudo agora, em todos os arquivos
```

### Windows: o `bash` do WSL atrapalha

Os hooks do Terraform são scripts bash. Se o `bash` que o terminal encontra primeiro for o do WSL
(`C:\Windows\System32\bash.exe`) e a distro instalada for só a `docker-desktop`, os hooks falham
com `execvpe(/bin/bash) failed`. O `gitleaks` passa, porque não usa bash. Corrija colocando o bash
do Git na frente do PATH da sessão:

```powershell
$env:Path = "C:\Program Files\Git\bin;C:\Program Files\Git\usr\bin;" + $env:Path
```

Ou rode o `pre-commit` de um terminal Git Bash.

## Os bloqueios foram testados

Arquivos temporários errados de propósito, apagados depois:

| Teste | Resultado |
|---|---|
| `.tf` mal formatado | `terraform fmt`: Failed |
| Variável sem tipo e não usada | `tflint`: Failed |
| Token falso no formato `ghp_...` | `gitleaks`: Failed (regra `github-pat`) |

## Trivy: corrigir ou justificar

O Trivy lê o código e aponta configurações inseguras. Sem nenhuma exceção ele apontou 9 regras
diferentes, listadas na tabela abaixo (duas só aparecem com o ALB ligado). A política adotada foi: **corrigir o que dá; o que não dá vira exceção escrita
no código, com a justificativa**. Uma exceção é uma linha `#trivy:ignore:<ID>` colada acima do recurso.

```bash
trivy config --skip-dirs "**/.terraform" --severity LOW,MEDIUM,HIGH,CRITICAL .
```

Para ver também o ALB e o autoscaling, que o Trivy não enxerga com os valores padrão:

```bash
trivy config --skip-dirs "**/.terraform" --severity LOW,MEDIUM,HIGH,CRITICAL \
  --tf-vars alb.tfvars examples/ecs-service
```

onde `alb.tfvars` contém `enable_alb = true` e `enable_autoscaling = true`. O arquivo é ignorado
pelo `.gitignore` (`*.tfvars`), então crie quando precisar.

| ID | Gravidade | Onde | Decisão |
|---|---|---|---|
| AWS-0345 | HIGH | `bootstrap/roles.tf` | **Corrigido.** A política de apply deixou de usar `s3:*` e lista as ações de bucket. |
| AWS-0132 | HIGH | `secure-s3`, bucket de state | Exceção. SSE-S3 (AES256) basta no estudo; chave KMS própria cobra por mês e por requisição. |
| AWS-0089 | LOW | `secure-s3`, bucket de state | Exceção. Log de acesso exigiria um segundo bucket só para logs. |
| AWS-0017 | LOW | log group do `ecs-service` | Exceção. Chave KMS cobra por mês; são logs de estudo. |
| AWS-0034 | LOW | cluster do `ecs-service` | Exceção. Container Insights cobra à parte. |
| AWS-0104 | CRITICAL | saída da task, `ecs-service` | Exceção. Só porta 443; os IPs do ECR e do CloudWatch variam. A alternativa são endpoints de VPC, que cobram por hora. |
| AWS-0178 | MEDIUM | VPC do `network` | Exceção. Flow logs geram custo de ingestão e saem do escopo do módulo. |
| AWS-0053 | HIGH | ALB (opcional) | Exceção. O ALB é público de propósito, é a entrada do serviço. |
| AWS-0054 | CRITICAL | listener HTTP do ALB (opcional) | Exceção. HTTPS exige certificado e domínio, fora do estudo. É um limite declarado do módulo. |

Resultado final: 0 achados nos 8 alvos, e também com ALB e autoscaling ligados.

### Antes de usar em produção

Cada exceção acima é uma escolha de estudo e de custo, não uma recomendação geral. Numa conta real,
reveja pelo menos: KMS próprio no S3 e no log group, HTTPS no ALB, flow logs na VPC e log de acesso
nos buckets.

## O que fica para depois

O `.terraform.lock.hcl` das pastas raiz é versionado. Para ele valer também no CI em Linux, falta
rodar `terraform providers lock` com várias plataformas. Isso baixa o provider de cada plataforma,
então será feito na Etapa 4, quando a pasta que o pipeline usa for definida.
