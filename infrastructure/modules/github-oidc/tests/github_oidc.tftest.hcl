# Mock-based tests: no AWS credentials or real resources needed.

mock_provider "aws" {
  override_resource {
    target = aws_iam_openid_connect_provider.github
    values = { arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com" }
  }
}

mock_provider "tls" {
  override_data {
    target = data.tls_certificate.github
    values = {
      certificates = [{
        sha1_fingerprint     = "6938fd4d98bab03faadb97b34396831e3780aea1"
        cert_pem             = "mock"
        is_ca                = true
        issuer               = "mock"
        max_path_length      = 0
        not_after            = "2030-01-01T00:00:00Z"
        not_before           = "2020-01-01T00:00:00Z"
        public_key_algorithm = "RSA"
        serial_number        = "1"
        signature_algorithm  = "SHA256-RSA"
        subject              = "mock"
        version              = 3
      }]
    }
  }
}

variables {
  name               = "test"
  github_org         = "example-org"
  github_repo        = "example-repo"
  github_environment = "dev"
  state_bucket_name  = "cobble-tfstate-123456789012"
  state_key          = "solution-a/workload/terraform.tfstate"
}

run "plan_role_is_only_for_pull_requests_and_main" {
  command = apply

  assert {
    condition     = jsondecode(aws_iam_role.plan.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == ["repo:example-org/example-repo:pull_request", "repo:example-org/example-repo:ref:refs/heads/main"]
    error_message = "The plan role must only trust pull requests and the main branch of this repo"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.plan_read_only.policy_arn == "arn:aws:iam::aws:policy/ReadOnlyAccess"
    error_message = "The plan role must be read-only"
  }
}

run "plan_role_cannot_read_data" {
  command = apply

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_role_policy.plan_no_data.policy).Statement :
      s.Effect == "Deny" && s.Action == "s3:GetObject" && s.NotResource == "arn:aws:s3:::cobble-tfstate-123456789012/*"
    ])
    error_message = "The plan role must not read bucket contents, except the state file"
  }
}

run "apply_role_needs_the_approved_environment" {
  command = apply

  assert {
    condition     = jsondecode(aws_iam_role.apply.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == ["repo:example-org/example-repo:environment:dev"]
    error_message = "The apply role must only trust runs in the named GitHub environment"
  }
}

run "plan_role_can_only_write_the_lock_file" {
  command = apply

  assert {
    condition = alltrue([
      for s in jsondecode(aws_iam_role_policy.plan_state.policy).Statement :
      !contains(flatten([s.Action]), "s3:PutObject") || s.Resource == "arn:aws:s3:::cobble-tfstate-123456789012/solution-a/workload/terraform.tfstate.tflock"
    ])
    error_message = "The plan role may write the lock file but never the state itself"
  }
}

run "tokens_must_be_meant_for_aws" {
  command = apply

  assert {
    condition = alltrue([for r in [aws_iam_role.plan, aws_iam_role.apply] :
    jsondecode(r.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"] == "sts.amazonaws.com"])
    error_message = "Both roles must require the sts.amazonaws.com audience"
  }
}
