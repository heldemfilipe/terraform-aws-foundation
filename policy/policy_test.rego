package main

import rego.v1

# Testes das políticas. Rodar com: opa test policy/ -v
# Cada teste monta um plan mínimo, no formato do `terraform show -json`, e confere as mensagens.

tags_ok := {"Project": "terraform-aws-foundation", "Environment": "dev"}

trava_total := {
	"block_public_acls": true,
	"block_public_policy": true,
	"ignore_public_acls": true,
	"restrict_public_buckets": true,
}

# Recurso a ser criado dentro de module.m.
t_recurso(tipo, after) := {
	"address": sprintf("module.m.%s.this", [tipo]),
	"module_address": "module.m",
	"type": tipo,
	"change": {"actions": ["create"], "after": after},
}

# Recurso na raiz (sem module_address).
t_raiz(tipo, after) := {
	"address": sprintf("%s.this", [tipo]),
	"type": tipo,
	"change": {"actions": ["create"], "after": after},
}

t_plano(recursos) := {"resource_changes": recursos}

t_bucket := t_recurso("aws_s3_bucket", {"tags": tags_ok, "tags_all": tags_ok})

t_cripto := t_recurso("aws_s3_bucket_server_side_encryption_configuration", {})

t_acesso := t_recurso("aws_s3_bucket_public_access_block", trava_total)

t_regra(after) := t_recurso("aws_vpc_security_group_ingress_rule", object.union({"tags": tags_ok, "tags_all": tags_ok}, after))

# --- tags ---

test_tags_completas_passam if {
	p := t_plano([t_recurso("aws_cloudwatch_log_group", {"tags": tags_ok, "tags_all": tags_ok})])
	count(deny) == 0 with input as p
}

test_tag_project_ausente_e_negada if {
	p := t_plano([t_recurso("aws_cloudwatch_log_group", {"tags": {}, "tags_all": {"Environment": "dev"}})])
	deny == {"module.m.aws_cloudwatch_log_group.this precisa da tag Project"} with input as p
}

test_sem_tags_e_tags_all_desconhecida_e_negado if {
	# Como no plan real: tags nulo e tags_all ausente (desconhecida até o apply).
	p := t_plano([t_recurso("aws_cloudwatch_log_group", {"tags": null})])
	deny == {
		"module.m.aws_cloudwatch_log_group.this precisa da tag Environment",
		"module.m.aws_cloudwatch_log_group.this precisa da tag Project",
	} with input as p
}

test_recurso_sem_suporte_a_tags_e_ignorado if {
	p := t_plano([t_recurso("aws_s3_bucket_versioning", {})])
	count(deny) == 0 with input as p
}

test_recurso_que_nao_e_criado_e_ignorado if {
	p := t_plano([{
		"address": "module.m.aws_cloudwatch_log_group.this",
		"type": "aws_cloudwatch_log_group",
		"change": {"actions": ["update"], "after": {"tags": null}},
	}])
	count(deny) == 0 with input as p
}

# --- S3 ---

test_bucket_completo_passa if {
	p := t_plano([t_bucket, t_cripto, t_acesso])
	count(deny) == 0 with input as p
}

test_bucket_na_raiz_completo_passa if {
	p := t_plano([
		t_raiz("aws_s3_bucket", {"tags": tags_ok, "tags_all": tags_ok}),
		t_raiz("aws_s3_bucket_server_side_encryption_configuration", {}),
		t_raiz("aws_s3_bucket_public_access_block", trava_total),
	])
	count(deny) == 0 with input as p
}

test_bucket_sem_criptografia_e_negado if {
	p := t_plano([t_bucket, t_acesso])
	deny == {"module.m.aws_s3_bucket.this precisa de criptografia (aws_s3_bucket_server_side_encryption_configuration)"} with input as p
}

test_bucket_sem_bloqueio_publico_e_negado if {
	p := t_plano([t_bucket, t_cripto])
	deny == {"module.m.aws_s3_bucket.this precisa do bloqueio total de acesso público (aws_s3_bucket_public_access_block)"} with input as p
}

test_bloqueio_publico_parcial_e_negado if {
	parcial := t_recurso("aws_s3_bucket_public_access_block", object.union(trava_total, {"restrict_public_buckets": false}))
	p := t_plano([t_bucket, t_cripto, parcial])
	deny == {"module.m.aws_s3_bucket.this precisa do bloqueio total de acesso público (aws_s3_bucket_public_access_block)"} with input as p
}

# --- security group ---

test_ssh_aberto_e_negado if {
	p := t_plano([t_regra({"cidr_ipv4": "0.0.0.0/0", "from_port": 22, "to_port": 22, "ip_protocol": "tcp"})])
	deny == {"module.m.aws_vpc_security_group_ingress_rule.this expõe porta administrativa para 0.0.0.0/0"} with input as p
}

test_rdp_dentro_de_faixa_e_negado if {
	p := t_plano([t_regra({"cidr_ipv4": "0.0.0.0/0", "from_port": 3000, "to_port": 4000, "ip_protocol": "tcp"})])
	count(deny) == 1 with input as p
}

test_todo_o_trafego_aberto_e_negado if {
	p := t_plano([t_regra({"cidr_ipv4": "0.0.0.0/0", "ip_protocol": "-1"})])
	count(deny) == 1 with input as p
}

test_ipv6_aberto_e_negado if {
	p := t_plano([t_regra({"cidr_ipv6": "::/0", "from_port": 22, "to_port": 22, "ip_protocol": "tcp"})])
	deny == {"module.m.aws_vpc_security_group_ingress_rule.this expõe porta administrativa para ::/0"} with input as p
}

test_https_aberto_passa if {
	p := t_plano([t_regra({"cidr_ipv4": "0.0.0.0/0", "from_port": 443, "to_port": 443, "ip_protocol": "tcp"})])
	count(deny) == 0 with input as p
}

test_ssh_de_rede_privada_passa if {
	p := t_plano([t_regra({"cidr_ipv4": "10.0.0.0/8", "from_port": 22, "to_port": 22, "ip_protocol": "tcp"})])
	count(deny) == 0 with input as p
}

test_ssh_aberto_em_regra_inline_e_negado if {
	sg := t_recurso("aws_security_group", {
		"tags": tags_ok,
		"tags_all": tags_ok,
		"ingress": [{"cidr_blocks": ["0.0.0.0/0"], "ipv6_cidr_blocks": [], "from_port": 22, "to_port": 22, "protocol": "tcp"}],
	})
	deny == {"module.m.aws_security_group.this expõe porta administrativa para 0.0.0.0/0"} with input as t_plano([sg])
}
