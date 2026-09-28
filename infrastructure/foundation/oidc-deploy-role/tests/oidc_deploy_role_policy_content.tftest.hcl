# Separate file so this gets its own independent state, not shared with
# oidc_deploy_role.tftest.hcl's mocked resources (mixing a real provider
# into that shared state would try to re-read the mocked resources for
# real and fail).
#
# aws_iam_policy_document is a local computation, not an AWS API call, so
# leaving "aws" real (just configured offline, with fake credentials and
# validation skipped) lets this test exercise deploy_permissions' actual
# logic instead of a mocked fabrication. command = plan only, never apply:
# nothing gets created, no real AWS call happens. This only works for
# deploy_permissions, not the trust policy — see oidc_deploy_role.tftest.hcl's
# header for why.

mock_provider "tls" {
  override_data {
    target = data.tls_certificate.github
    values = {
      certificates = [
        { sha1_fingerprint = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }
      ]
    }
  }
}

provider "aws" {
  region                      = "ap-southeast-2"
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

variables {
  project_name = "test"
  github_org   = "some-org"
  github_repo  = "some-repo"
}

run "deploy_policy_scoped_to_expected_services" {
  command = plan

  assert {
    condition = toset(jsondecode(data.aws_iam_policy_document.deploy_permissions.json).Statement[0].Action) == toset([
      "ec2:*", "s3:*", "iam:*", "cloudtrail:*", "guardduty:*", "budgets:*", "kms:*", "logs:*", "sts:GetCallerIdentity"
    ])
    error_message = "Deploy role policy action list changed — update this test (and README/ADR 0003) if that's intentional"
  }
}
