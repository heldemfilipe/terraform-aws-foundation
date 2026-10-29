mock_provider "aws" {}

variables {
  account_id   = "123456789012"
  budget_email = "teste@exemplo.com"
}

run "role_de_plan_so_aceita_pull_request" {
  command = plan

  assert {
    condition     = output.github_subs["plan"] == "repo:heldemfilipe/terraform-aws-foundation:pull_request"
    error_message = "A role de plan precisa aceitar só tokens de pull_request deste repositório."
  }
}

run "role_de_apply_so_aceita_o_environment_production" {
  command = plan

  assert {
    condition     = output.github_subs["apply"] == "repo:heldemfilipe/terraform-aws-foundation:environment:production"
    error_message = "A role de apply precisa exigir o environment production deste repositório."
  }
}

run "nenhum_sub_tem_curinga" {
  command = plan

  assert {
    condition     = alltrue([for s in values(output.github_subs) : !strcontains(s, "*")])
    error_message = "Nenhum sub pode conter curinga."
  }
}

run "plan_e_apply_sao_roles_diferentes" {
  command = plan

  assert {
    condition     = output.github_subs["plan"] != output.github_subs["apply"]
    error_message = "As roles de plan e apply não podem aceitar o mesmo sub."
  }
}

run "repositorio_com_curinga_e_rejeitado" {
  command = plan

  variables {
    github_repo = "heldemfilipe/*"
  }

  expect_failures = [var.github_repo]
}

run "account_id_invalido_e_rejeitado" {
  command = plan

  variables {
    account_id = "123"
  }

  expect_failures = [var.account_id]
}

run "email_invalido_e_rejeitado" {
  command = plan

  variables {
    budget_email = "invalido"
  }

  expect_failures = [var.budget_email]
}

run "role_de_drift_so_aceita_a_main" {
  command = plan

  assert {
    condition     = output.github_subs["drift"] == "repo:heldemfilipe/terraform-aws-foundation:ref:refs/heads/main"
    error_message = "A role de drift precisa aceitar só tokens da branch main deste repositório."
  }
}

run "cada_role_tem_um_sub_diferente" {
  command = plan

  assert {
    condition     = length(distinct(values(output.github_subs))) == length(output.github_subs)
    error_message = "Duas roles não podem aceitar o mesmo sub."
  }
}