mock_provider "aws" {}

variables {
  account_id = "123456789012"
}

run "nome_cabe_na_role_de_apply" {
  command = plan

  assert {
    condition     = startswith(output.bucket_name, "foundation-lab-")
    error_message = "O bucket precisa começar com foundation-lab-, senão a role de apply não consegue criá-lo."
  }
}

run "account_id_invalido_e_rejeitado" {
  command = plan

  variables {
    account_id = "123"
  }

  expect_failures = [var.account_id]
}