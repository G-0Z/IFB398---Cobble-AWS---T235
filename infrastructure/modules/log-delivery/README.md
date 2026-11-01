# Log delivery (`log-delivery`)

**What it builds:** an encrypted CloudWatch log group, and the permission an
AWS service needs to write into it, and nothing more.

**Used by:** the audit trail (`security-baseline`) and the network traffic
logs (`network`).

## What you get

| Part | Why |
|---|---|
| Log group | Stores the logs, encrypted, for a set number of days |
| Role | Can only be used by the one AWS service named (for example, CloudTrail) |
| Role policy | Lets that service write to this one log group, and nothing else |

## Good to know

- The permission for CloudWatch Logs to use the encryption key is granted where the key is defined (`security-baseline/kms.tf`), not here.
- The policies are written in a way the tests can check for real, without AWS.

## Usage

How it's called in [`modules/network/flow-logs.tf`](../../modules/network/flow-logs.tf):

```hcl
module "flow_log_destination" {
  source = "../log-delivery"

  log_group_name    = "/${var.project_name}/vpc-flow-logs"
  retention_in_days = 30
  kms_key_arn       = var.kms_key_arn
  role_name         = "${var.project_name}-vpc-flow-logs"
  service_principal = "vpc-flow-logs.amazonaws.com"
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
| kms\_key\_arn | KMS key that encrypts the log group. Its key policy must allow the CloudWatch Logs service. | `string` | n/a | yes |
| log\_group\_name | CloudWatch Logs group name, e.g. "/cobble/cloudtrail". | `string` | n/a | yes |
| retention\_in\_days | How long CloudWatch keeps the logs. | `number` | n/a | yes |
| role\_name | Name of the IAM role the delivering service assumes (also used for its inline policy). | `string` | n/a | yes |
| service\_principal | AWS service that writes the logs, e.g. "cloudtrail.amazonaws.com" or "vpc-flow-logs.amazonaws.com". | `string` | n/a | yes |

### Outputs

| Name | Description |
| ---- | ----------- |
| log\_group\_arn | ARN of the log group, without the trailing ":*". |
| role\_arn | ARN of the role the delivering service assumes. |
<!-- END_TF_DOCS -->
