# Exemplo: secure-s3

Uso mínimo do módulo [`secure-s3`](../../modules/secure-s3). O provider usa credenciais
falsas e desliga as checagens na AWS, então nada é criado e não há custo.

```bash
terraform init -backend=false
terraform plan
```

Resultado esperado: `Plan: 5 to add, 0 to change, 0 to destroy`, com todos os recursos sob
`module.bucket`.

Para usar na AWS de verdade, remova o bloco `provider` com credenciais falsas e configure o
acesso do seu jeito (SSO, variáveis de ambiente).
