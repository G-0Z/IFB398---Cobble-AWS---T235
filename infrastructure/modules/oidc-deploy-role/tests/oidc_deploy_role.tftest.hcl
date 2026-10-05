# Fully-mocked aws/tls providers: safe for testing literal/static config
# (names, the OIDC provider URL, client_id_list) since those values aren't
# routed through a mocked (and therefore fabricated) data source. For the
# deploy_permissions policy's actual JSON content, see
# oidc_deploy_role_policy_content.tftest.hcl (a separate file, since it
# needs a real, non-mocked provider — mixing that into this file's shared
# state would try to re-read these mocked resources for real and fail).
#
# The trust policy's actual sub/aud restriction isn't covered by a test
# here at all — it depends on aws_iam_openid_connect_provider.github.arn,
# which is unknown at plan time for a resource that doesn't exist yet, and
# genuinely applying this config needs a real AWS account. That property
# is instead meant to be proven by actually assuming the role from GitHub
# Actions (see the suggestion in this module's README).

mock_provider "aws" {
  # Both consuming resources validate their policy/assume_role_policy
  # argument as real JSON; the mocked aws_iam_policy_document.json would
  # otherwise be a fabricated non-JSON string. This doesn't test either
  # document's actual content, just lets the resources plan/apply cleanly.
  override_data {
    target = data.aws_iam_policy_document.trust
    values = {
      json = jsonencode({ Version = "2012-10-17", Statement = [] })
    }
  }

  override_data {
    target = data.aws_iam_policy_document.deploy_permissions
    values = {
      json = jsonencode({ Version = "2012-10-17", Statement = [] })
    }
  }
}

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

variables {
  project_name = "test"
  github_org   = "some-org"
  github_repo  = "some-repo"
}

run "oidc_provider_configured_for_github_actions" {
  command = apply

  assert {
    condition     = aws_iam_openid_connect_provider.github.url == "https://token.actions.githubusercontent.com"
    error_message = "OIDC provider URL must be GitHub Actions' token issuer"
  }

  assert {
    condition     = contains(aws_iam_openid_connect_provider.github.client_id_list, "sts.amazonaws.com")
    error_message = "OIDC provider must accept the sts.amazonaws.com audience"
  }
}

run "role_and_policy_use_project_prefix" {
  command = apply

  assert {
    condition     = aws_iam_role.deploy.name == "test-github-deploy"
    error_message = "Role name should be <project_name>-github-deploy"
  }

  assert {
    condition     = aws_iam_role_policy.deploy.name == "test-github-deploy-permissions"
    error_message = "Inline policy name should be <project_name>-github-deploy-permissions"
  }
}
