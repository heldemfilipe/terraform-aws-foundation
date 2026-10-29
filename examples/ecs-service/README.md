# Exemplo: ecs-service

Une os módulos [`network`](../../modules/network) e [`ecs-service`](../../modules/ecs-service):
uma VPC com duas zonas e um serviço Fargate nas sub-redes privadas, com `desired_count = 0`. O
provider usa credenciais falsas e desliga as checagens na AWS, então nada é criado e não há custo.

```bash
terraform init -backend=false
terraform plan
```

Para ver o ALB no plan (cobrado por hora numa conta real):

```bash
terraform plan -var enable_alb=true
```

Para ver o autoscaling:

```bash
terraform plan -var enable_autoscaling=true
```
