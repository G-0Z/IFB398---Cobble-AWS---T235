# Step 2 runs from the management account (same sign-in as step 1). The
# default provider works inside the Security account through the
# OrganizationAccountAccessRole created in step 1. The "management" provider
# is used only for the organisation-wide CloudTrail and the management
# account's own Config recorder.

locals {
  tags = {
    Application = "Cobbled"
    Environment = "security"
    ManagedBy   = "IaC"
    Owner       = "Cyber Security Centre"
    CostCentre  = "Cobble"
    DataClass   = "Confidential"
    Criticality = "High"
  }
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.security_account_id]

  assume_role {
    role_arn = "arn:aws:iam::${var.security_account_id}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  alias               = "management"
  region              = var.aws_region
  allowed_account_ids = [var.management_account_id]

  default_tags {
    tags = local.tags
  }
}
