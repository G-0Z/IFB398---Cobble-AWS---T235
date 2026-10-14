# Inputs for the PoC environment. Committed on purpose: nothing here is
# secret, and one shared file means every teammate deploys the same thing.
# Terraform loads *.auto.tfvars automatically; no -var-file needed.
# Never put secrets in this file.

account_id = "669591255093"
aws_region = "ap-southeast-2"

project_name = "cobble"

# Shared team alert address.
alert_email = "t235cobbleaws@gmail.com"

# Near-zero spend target: any real spend should alert.
budget_limit    = 1
budget_currency = "USD" # AWS budgets only work in US dollars. US$1 is about A$1.45

# Must match the repo GitHub Actions deploys from.
github_org  = "G-0Z"
github_repo = "IFB398---Cobble-AWS---T235"

# false once Solution A's landing zone (1-organization) runs in this
# account: it then owns the account's GuardDuty detector.
enable_guardduty = true

# Optional demo web app (see main.tf). Leave false except during demos.
enable_demo_app = false

vpc_cidr             = "10.20.0.0/16"
public_subnet_cidrs  = ["10.20.0.0/24", "10.20.1.0/24"]
private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]

# Required tags (Implementation Guide naming standard).
owner       = "IFB398-T235"
cost_centre = "IFB398-capstone"
data_class  = "Internal"
criticality = "Low"
