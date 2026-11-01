# Account safety settings (`account-baseline`)

**What it builds:** the set-and-forget safety settings every Solution A
account gets, plus a history of every resource's settings (AWS Config),
sent to the central Security account.

**Used by:** Solution A (`2-security`, for the security and management
accounts; `3-shared-services`; and each environment). The
Solution A demo switches it off, because it shares an account with
Solution B and the team's IAM users.

## What you get

| Setting | Why | Benchmark |
|---|---|---|
| Account-wide block on public buckets | No bucket in the account can ever be made public | CIS 2.1.4, AWS FSBP S3.1 |
| New disks always encrypted | Every new disk is encrypted automatically | CIS 2.2.1, AWS FSBP EC2.7 |
| Strong password rules | A backstop in case an IAM user is ever created | CIS 1.8, 1.9 |
| Configuration history (AWS Config) | A record of how every resource's settings change over time, kept in the Security account | CIS 3.3, AWS FSBP Config.1 |

## Usage

How it's called in [`solution-a/landing-zone/2-security/detection.tf`](../../solution-a/landing-zone/2-security/detection.tf):

```hcl
module "account_baseline" {
  source = "../../../modules/account-baseline"

  name               = "cobble-security"
  config_bucket_name = module.config_bucket.bucket_name
  config_kms_key_arn = aws_kms_key.security.arn
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
| config\_bucket\_name | Central AWS Config bucket in the Security account (output of solution-a/landing-zone/2-security). | `string` | n/a | yes |
| config\_kms\_key\_arn | KMS key that encrypts the central Config bucket (output of solution-a/landing-zone/2-security). | `string` | n/a | yes |
| name | Prefix for resource names, e.g. "cobble-dev". | `string` | n/a | yes |

### Outputs

| Name | Description |
| ---- | ----------- |
| config\_recorder\_name | AWS Config recorder name. |
<!-- END_TF_DOCS -->
