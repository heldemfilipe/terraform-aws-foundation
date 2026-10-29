# ecs-service

Serviço no ECS com Fargate: cluster, definição da tarefa, logs no CloudWatch, grupo de
segurança sem entrada, duas roles e, opcionalmente, um Application Load Balancer e autoscaling
por CPU. A **task role nasce sem nenhuma permissão**.

## Uso

```hcl
module "servico" {
  source = "git::https://github.com/heldemfilipe/terraform-aws-foundation.git//modules/ecs-service?ref=v1.0.0"

  nome          = "orders-api"
  imagem        = "123456789012.dkr.ecr.us-east-1.amazonaws.com/orders-api:1.0.0"
  vpc_id        = module.network.vpc_id
  subnet_ids    = module.network.private_subnet_ids
  desired_count = 0
}
```

Um exemplo completo, junto com o módulo `network`, está em [examples/ecs-service](../../examples/ecs-service).

## O que o módulo cria

| Recurso | Quando | Observação |
|---|---|---|
| Log group | sempre | `/ecs/<nome>`, retenção de 7 dias por padrão |
| Cluster ECS | sempre | Container Insights desligado (cobra à parte) |
| Execution role | sempre | Política gerenciada `AmazonECSTaskExecutionRolePolicy`: puxar imagem e escrever logs |
| Task role | sempre | Sem permissões; recebe uma política só se `task_policy_json` for informada |
| Task definition | sempre | Fargate, rede `awsvpc`, logs via `awslogs` |
| Grupo de segurança das tarefas | sempre | Sem entrada; saída só HTTPS (443) |
| Service | sempre | Tarefas sem IP público |
| ALB, target group, listener e regras | `enable_alb = true` | Escuta na porta 80; só o ALB alcança as tarefas |
| Target de autoscaling e política de CPU | `enable_autoscaling = true` | Acompanha a CPU média do serviço |

## Duas roles, dois papéis

| Role | Quem usa | Para quê |
|---|---|---|
| Execution role | O próprio ECS | Puxar a imagem e escrever logs |
| Task role | O aplicativo dentro do contêiner | Falar com a AWS (S3, filas etc.). Começa vazia: informe `task_policy_json` só com o que o app precisa |

## Custo

| Item | Custo |
|---|---|
| Cluster, log group, roles, grupos de segurança | Sem cobrança relevante |
| Tarefas Fargate rodando | **Cobradas por segundo** de CPU e memória |
| ALB (`enable_alb = true`) | **Cobrado por hora**, mesmo sem tráfego |

Com `desired_count = 0` o serviço existe sem tarefas, e o Fargate não cobra. O ALB vem desligado
por padrão.

## Decisões e limites

- **Sem bloco `provider`, sem `data` que consulte a AWS.** O `plan` funciona sem conta e o módulo
  é testável com `mock_provider`.
- **Trust policies com `jsonencode`.** Com `mock_provider`, `data "aws_iam_policy_document"` volta
  com texto aleatório e o IAM recusa; `jsonencode` gera o JSON real.
- **`desired_count` vale só na criação.** O serviço ignora mudanças posteriores nesse campo, porque
  o autoscaling passa a controlá-lo; o Terraform não deve brigar com ele.
- **O ALB escuta só em HTTP (80).** HTTPS exige certificado e domínio, fora do escopo do estudo; o
  achado do scanner de segurança é registrado como exceção justificada na Etapa 3.
- **Sub-redes privadas sem NAT não alcançam a internet.** Para puxar a imagem de um registro
  externo é preciso habilitar o NAT no módulo `network` ou criar endpoints de VPC.
- **Container Insights desligado.** Reduz custo; ligue se precisar de métricas detalhadas.

## Testes

```bash
cd modules/ecs-service
terraform init -backend=false
terraform test
```

Os testes usam `mock_provider`, então não precisam de conta AWS:

| Arquivo | O que confere |
|---|---|
| `tests/servico.tftest.hcl` | Porta, logs, Fargate com `awsvpc`, sem IP público, retenção, trust das roles, task role sem permissões, validação de CPU, imagem e sub-redes |
| `tests/alb_autoscaling.tftest.hcl` | ALB e autoscaling desligados por padrão, ligados por variável, duas sub-redes para o ALB, limites do autoscaling |

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
| [aws_appautoscaling_policy.cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.alb_para_tarefas](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.alb_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.from_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_ingress_cidrs"></a> [alb\_ingress\_cidrs](#input\_alb\_ingress\_cidrs) | Origens que podem acessar o ALB na porta 80. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_alb_subnet_ids"></a> [alb\_subnet\_ids](#input\_alb\_subnet\_ids) | Sub-redes públicas do ALB. Exige ao menos duas quando enable\_alb = true. | `list(string)` | `[]` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | CPU da tarefa Fargate, em unidades (256 = 0,25 vCPU). | `number` | `256` | no |
| <a name="input_cpu_target_percent"></a> [cpu\_target\_percent](#input\_cpu\_target\_percent) | CPU média alvo do autoscaling, em porcentagem. | `number` | `60` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Quantas tarefas manter rodando. Use 0 para não gastar nada. | `number` | `1` | no |
| <a name="input_enable_alb"></a> [enable\_alb](#input\_enable\_alb) | Cria um Application Load Balancer na frente do serviço (cobrado por hora). | `bool` | `false` | no |
| <a name="input_enable_autoscaling"></a> [enable\_autoscaling](#input\_enable\_autoscaling) | Liga o autoscaling por CPU. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Variáveis de ambiente do contêiner. | `map(string)` | `{}` | no |
| <a name="input_health_check_path"></a> [health\_check\_path](#input\_health\_check\_path) | Caminho usado pelo ALB para checar a saúde das tarefas. | `string` | `"/"` | no |
| <a name="input_imagem"></a> [imagem](#input\_imagem) | Imagem do contêiner, por exemplo nginx:1.27. | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Dias de retenção dos logs no CloudWatch. | `number` | `7` | no |
| <a name="input_max_capacity"></a> [max\_capacity](#input\_max\_capacity) | Máximo de tarefas com autoscaling. | `number` | `2` | no |
| <a name="input_memoria"></a> [memoria](#input\_memoria) | Memória da tarefa Fargate, em MiB. | `number` | `512` | no |
| <a name="input_min_capacity"></a> [min\_capacity](#input\_min\_capacity) | Mínimo de tarefas com autoscaling. | `number` | `1` | no |
| <a name="input_nome"></a> [nome](#input\_nome) | Nome do serviço. Prefixa os recursos. | `string` | n/a | yes |
| <a name="input_porta"></a> [porta](#input\_porta) | Porta em que o contêiner escuta. | `number` | `8080` | no |
| <a name="input_region"></a> [region](#input\_region) | Região usada na configuração de logs. | `string` | `"us-east-1"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Sub-redes onde as tarefas rodam (use as privadas). | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags aplicadas aos recursos. | `map(string)` | `{}` | no |
| <a name="input_task_policy_json"></a> [task\_policy\_json](#input\_task\_policy\_json) | Política IAM (JSON) com as permissões que o aplicativo precisa. Sem ela, a task role não tem nenhuma. | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID da VPC onde o serviço roda. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | Endereço do ALB, ou null se enable\_alb for false. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Nome do cluster ECS. |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | Nome do grupo de logs no CloudWatch. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID do grupo de segurança das tarefas. |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Nome do serviço ECS. |
| <a name="output_task_role_arn"></a> [task\_role\_arn](#output\_task\_role\_arn) | ARN da task role, para anexar permissões do aplicativo. |
<!-- END_TF_DOCS -->
