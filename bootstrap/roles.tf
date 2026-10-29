locals {
  state_key = "foundation/terraform.tfstate"

  # O "sub" separa quem pode fazer o quê.
  github_subs = {
    plan  = "repo:${var.github_repo}:pull_request"
    apply = "repo:${var.github_repo}:environment:${var.github_environment}"
  }
}

# --- Trust policy: quem pode assumir cada role ---

data "aws_iam_policy_document" "trust" {
  for_each = local.github_subs

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [each.value]
    }
  }
}

resource "aws_iam_role" "foundation" {
  for_each = local.github_subs

  name                 = "foundation-${each.key}"
  assume_role_policy   = data.aws_iam_policy_document.trust[each.key].json
  max_session_duration = 3600
}

# --- Role de plan: lê tudo, usa o state e só escreve o arquivo de lock ---

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.foundation["plan"].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "plan_state" {
  statement {
    sid       = "ListaBucketDeState"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "LeOState"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.state.arn}/${local.state_key}"]
  }

  statement {
    sid       = "UsaOLock"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/${local.state_key}.tflock"]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "state-e-lock"
  role   = aws_iam_role.foundation["plan"].id
  policy = data.aws_iam_policy_document.plan_state.json
}

# --- Role de apply: permissões estreitas, nunca AdministratorAccess ---

data "aws_iam_policy_document" "apply" {
  statement {
    sid       = "ListaBucketDeState"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "LeEEscreveOState"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/foundation/*"]
  }

  # Só buckets de laboratório. O bucket de state fica de fora de propósito.
  statement {
    sid     = "GerenciaBucketsDoProjeto"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::foundation-lab-*",
      "arn:aws:s3:::foundation-lab-*/*",
    ]
  }
}

resource "aws_iam_role_policy" "apply" {
  name   = "recursos-do-projeto"
  role   = aws_iam_role.foundation["apply"].id
  policy = data.aws_iam_policy_document.apply.json
}