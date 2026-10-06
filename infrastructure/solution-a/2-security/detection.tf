# Threat detection and posture checks, switched on for every account in the
# organisation (including accounts added later). The Security account was
# made the delegated administrator for each of these in step 1.

# --- GuardDuty: spots suspicious behaviour --------------------------------
# e.g. stolen credentials being used, crypto-mining, contact with known
# malicious IP addresses.

resource "aws_guardduty_detector" "this" {
  enable = true
}

resource "aws_guardduty_organization_configuration" "this" {
  detector_id                      = aws_guardduty_detector.this.id
  auto_enable_organization_members = "ALL"
}

# --- Security Hub: one place for every finding ----------------------------
# Collects GuardDuty findings and checks every account against two standards:
#   - AWS Foundational Security Best Practices
#   - CIS AWS Foundations Benchmark v3.0.0

resource "aws_securityhub_account" "this" {
  enable_default_standards = false
}

resource "aws_securityhub_organization_configuration" "this" {
  auto_enable           = true
  auto_enable_standards = "DEFAULT"

  depends_on = [aws_securityhub_account.this]
}

resource "aws_securityhub_standards_subscription" "fsbp" {
  standards_arn = "arn:aws:securityhub:${local.region}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.this]
}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:${local.region}::standards/cis-aws-foundations-benchmark/v/3.0.0"
  depends_on    = [aws_securityhub_account.this]
}

# --- AWS Config aggregator: every account's settings in one view ----------

resource "aws_iam_role" "config_aggregator" {
  name = "cobble-config-aggregator"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_aggregator" {
  role       = aws_iam_role.config_aggregator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

#tfsec:ignore:aws-config-aggregate-all-regions -- the restrict-regions SCP blocks every other region, so the home region holds all resources.
resource "aws_config_configuration_aggregator" "organization" {
  name = "cobble-organization"

  organization_aggregation_source {
    regions  = [local.region]
    role_arn = aws_iam_role.config_aggregator.arn
  }

  depends_on = [aws_iam_role_policy_attachment.config_aggregator]
}

# --- IAM Access Analyzer: anything shared outside the organisation --------
# Flags any bucket, key, role or other resource that someone outside the
# organisation can reach.

resource "aws_accessanalyzer_analyzer" "organization" {
  analyzer_name = "cobble-organization"
  type          = "ORGANIZATION"
}

# --- Config recording for the Security and management accounts ------------
# (Every other account records Config in its own step.)

module "account_baseline" {
  source = "../../modules/account-baseline"

  name               = "cobble-security"
  config_bucket_name = module.config_bucket.bucket_name
  config_kms_key_arn = aws_kms_key.security.arn
}

module "management_account_baseline" {
  source = "../../modules/account-baseline"
  providers = {
    aws = aws.management
  }

  name               = "cobble-management"
  config_bucket_name = module.config_bucket.bucket_name
  config_kms_key_arn = aws_kms_key.security.arn
}
