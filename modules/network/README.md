# network

VPC com sub-redes públicas e privadas em uma ou mais zonas de disponibilidade. O **NAT gateway
vem desligado por padrão**, porque cobra por hora mesmo sem tráfego.

## Uso

```hcl
module "network" {
  source = "git::https://github.com/heldemfilipe/terraform-aws-foundation.git//modules/network?ref=v1.0.0"

  nome = "lab"
  azs  = ["us-east-1a", "us-east-1b"]
}
```

Um exemplo completo está em [examples/network](../../examples/network).

## O que o módulo cria

| Recurso | Quantidade | Observação |
|---|---|---|
| VPC | 1 | DNS e hostnames ligados |
| Internet gateway | 1 | Saída das sub-redes públicas |
| Sub-redes públicas | 1 por zona | Rota `0.0.0.0/0` para o internet gateway; não atribuem IP público automaticamente |
| Sub-redes privadas | 1 por zona | Sem rota para a internet, a menos que o NAT esteja ligado |
| Security group padrão | 1 | Esvaziado: sem nenhuma regra de entrada ou saída |
| NAT gateway e IP elástico | 0 ou 1 | Só com `enable_nat_gateway = true` |

## Endereçamento

Cada sub-rede é um `/24` calculado a partir de `cidr_block` (padrão `10.0.0.0/16`):

| Sub-rede | Fórmula | Exemplo com 2 zonas |
|---|---|---|
| Pública da zona `i` | `cidrsubnet(cidr_block, 8, i)` | `10.0.0.0/24`, `10.0.1.0/24` |
| Privada da zona `i` | `cidrsubnet(cidr_block, 8, i + 100)` | `10.0.100.0/24`, `10.0.101.0/24` |

## Custo

| Item | Custo |
|---|---|
| VPC, sub-redes, tabelas de rota, internet gateway | Sem cobrança |
| NAT gateway + IP elástico (`enable_nat_gateway = true`) | **Cobrado por hora**, mesmo sem tráfego |

Por isso o padrão é `false`. Com ele, as sub-redes privadas não alcançam a internet.
Um único NAT atende todas as zonas, o que é mais barato e menos resiliente do que um por zona.

## Decisões

- **As zonas vêm por variável (`azs`).** O módulo não consulta `aws_availability_zones`, então o
  `plan` funciona sem conta AWS e o resultado é previsível.
- **Sub-redes públicas não atribuem IP público automaticamente.** IPv4 público é cobrado, e quem
  precisa dele (um balanceador, por exemplo) o recebe de outro recurso.
- **Security group padrão esvaziado.** Nada usa o grupo padrão por engano com regras abertas.
- **Sem flow logs.** Ficam fora do escopo do módulo; o achado do scanner de segurança é registrado
  como exceção justificada na Etapa 3.

## Testes

```bash
cd modules/network
terraform init -backend=false
terraform test
```

Os testes (`tests/rede.tftest.hcl`) usam `mock_provider`, então não precisam de conta AWS.

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
| [aws_default_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azs"></a> [azs](#input\_azs) | Zonas de disponibilidade, uma sub-rede pública e uma privada em cada. | `list(string)` | n/a | yes |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | Bloco CIDR da VPC. Precisa ser /20 ou maior, para caber as sub-redes /24. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Liga o NAT gateway (cobrado por hora). Desligado por padrão. | `bool` | `false` | no |
| <a name="input_nome"></a> [nome](#input\_nome) | Prefixo usado no nome dos recursos. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags aplicadas aos recursos. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nat_gateway_enabled"></a> [nat\_gateway\_enabled](#output\_nat\_gateway\_enabled) | Indica se o NAT gateway foi criado. |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | IDs das sub-redes privadas, na ordem das zonas. |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | IDs das sub-redes públicas, na ordem das zonas. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID da VPC. |
<!-- END_TF_DOCS -->
