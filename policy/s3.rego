package main

import rego.v1

# Módulo onde o recurso mora; vazio na raiz.
modulo(rc) := object.get(rc, "module_address", "")

criados(tipo) := {rc |
	some rc in input.resource_changes
	rc.type == tipo
	"create" in rc.change.actions
}

# Os quatro bloqueios precisam estar ligados.
bloqueio_total(after) if {
	after.block_public_acls == true
	after.block_public_policy == true
	after.ignore_public_acls == true
	after.restrict_public_buckets == true
}

com_criptografia := {modulo(rc) | some rc in criados("aws_s3_bucket_server_side_encryption_configuration")}

com_bloqueio := {modulo(rc) |
	some rc in criados("aws_s3_bucket_public_access_block")
	bloqueio_total(rc.change.after)
}

deny contains msg if {
	some bucket in criados("aws_s3_bucket")
	not modulo(bucket) in com_criptografia
	msg := sprintf("%s precisa de criptografia (aws_s3_bucket_server_side_encryption_configuration)", [bucket.address])
}

deny contains msg if {
	some bucket in criados("aws_s3_bucket")
	not modulo(bucket) in com_bloqueio
	msg := sprintf("%s precisa do bloqueio total de acesso público (aws_s3_bucket_public_access_block)", [bucket.address])
}
