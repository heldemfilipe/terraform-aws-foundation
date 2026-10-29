# Exemplo: network

Uso do módulo [`network`](../../modules/network) com duas zonas e NAT desligado. O provider usa
credenciais falsas e desliga as checagens na AWS, então nada é criado e não há custo.

```bash
terraform init -backend=false
terraform plan
```

Para ver o NAT, rode `terraform plan -var enable_nat=true`. O plan passa a incluir um IP elástico,
um NAT gateway e uma rota privada, que seriam cobrados por hora numa conta real.
