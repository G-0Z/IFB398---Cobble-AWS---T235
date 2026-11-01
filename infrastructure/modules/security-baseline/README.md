# Account security baseline (`security-baseline`)

**What it builds:** Solution B's core security in one package: an
encryption key, an audit trail of every action (CloudTrail), threat
detection (GuardDuty), and the bucket that collects access logs from the
other buckets.

**Used by:** Solution B. Solution A spreads the same controls across its
Security account (`landing-zone/2-security`) and the `access-log-bucket`
module.

## What's in each file

| File | Holds |
|---|---|
| `kms.tf` | The account's encryption key and who may use it |
| `cloudtrail.tf` | The audit trail, its locked-down bucket (`s3-bucket`), and its searchable copy in CloudWatch (`log-delivery`) |
| `access-logs.tf` | The access-log bucket (the header explains why it's written by hand) |
| `guardduty.tf` | Threat detection. Optional, see below |
| `data.tf` | Looks up the current account and region |

## Good to know

- The audit trail is deleted when Solution B is torn down, an accepted trade-off for a demo platform. Solution A keeps it in a separate account where it can't be deleted.
- The automated tests can't check the content of the key and bucket policies (the pretend AWS can't render them). The bucket hardening and the log delivery role are tested in their own modules.

## Usage

How it's called in [`solution-b/main.tf`](../../solution-b/main.tf):

```hcl
module "security_baseline" {
  source = "../modules/security-baseline"

  project_name     = var.project_name
  enable_guardduty = var.enable_guardduty
}
```

## Reference

Generated from the module's code by [terraform-docs](https://terraform-docs.io/), so it's always
complete. Don't edit it by hand: run `terraform-docs -c ../.terraform-docs.yml .`
in this folder after changing a variable or output.

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.10 |
| aws | ~> 5.0 |

### Providers

| Name | Version |
| ---- | ------- |
| aws | ~> 5.0 |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| project\_name | Naming prefix. | `string` | n/a | yes |
| enable\_guardduty | Turn on GuardDuty in this account. false when something else already manages the account's detector (Solution A's landing zone). | `bool` | `true` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| access\_log\_bucket\_id | Shared S3 access-log destination bucket, for other buckets' server access logging. |
| guardduty\_detector\_id | GuardDuty detector ID, or null when enable\_guardduty is false. |
| kms\_key\_arn | ARN of the shared logging/data KMS key. |
| trail\_arn | ARN of the CloudTrail trail. |
| trail\_bucket\_name | S3 bucket holding CloudTrail logs. |
<!-- END_TF_DOCS -->
