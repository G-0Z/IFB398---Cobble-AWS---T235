# Access-log bucket (`access-log-bucket`)

**What it builds:** a locked-down bucket that collects access logs from the
other buckets in the account, and optionally from load balancers.

**Used by:** Solution A (every account). Solution B has its own version
inside `security-baseline`.

## What you get

| Part | Why |
|---|---|
| S3 bucket, versioned | Where the logs land. Deleted or overwritten logs can be recovered |
| Public access blocked | The logs can never be made public |
| Encryption (AWS-managed) | Logs are encrypted at rest. AWS's log delivery only supports its own keys here, not ours |
| Clean-up rule | Deletes logs after `log_retention_days`, so storage doesn't grow forever |
| Bucket policy | Only AWS's logging service (and optionally load balancers) can write, and only over HTTPS |

Further reading: [S3 security best practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html).

## Usage

How it's called in [`solution-a/landing-zone/2-security/log-archive.tf`](../../solution-a/landing-zone/2-security/log-archive.tf):

```hcl
module "access_logs" {
  source = "../../../modules/access-log-bucket"

  bucket_name   = "cobble-security-access-logs-${local.security_account_id}"
  force_destroy = var.force_destroy_buckets
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
| bucket\_name | Globally unique bucket name. | `string` | n/a | yes |
| force\_destroy | Let `terraform destroy` delete the bucket even when it holds logs. true for test environments; false for production. | `bool` | n/a | yes |
| allow\_load\_balancer\_logs | Also accept Application Load Balancer access logs (under the alb/ prefix). | `bool` | `false` | no |
| log\_retention\_days | Delete log files after this many days. | `number` | `365` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| bucket\_arn | Bucket ARN. |
| bucket\_id | Bucket name, for other buckets' access\_log\_bucket\_id and load balancer access logs. |
<!-- END_TF_DOCS -->
