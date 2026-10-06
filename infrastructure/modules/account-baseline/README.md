# `account-baseline` module

**In one sentence:** the set-and-forget safety settings every Solution A
account gets, plus AWS Config recording into the central Security account.

**Used by:** Solution A (`3-shared-services` and every workload environment).
Solution B doesn't use it (single account, cost near zero).

## What it creates

| Resource | Why | Benchmark |
|---|---|---|
| S3 account public access block | No bucket in the account can be made public | CIS 2.1.4, FSBP S3.1 |
| EBS encryption by default | Every new disk is encrypted | CIS 2.2.1, FSBP EC2.7 |
| IAM password policy | Backstop if an IAM user is ever created | CIS 1.8, 1.9 |
| AWS Config recorder + delivery | History of every resource's settings, sent to the central bucket | CIS 3.3, FSBP Config.1 |

## Inputs

| Name | Meaning |
|---|---|
| `name` | Prefix for resource names |
| `config_bucket_name` | Central Config bucket (from `2-security` outputs) |
| `config_kms_key_arn` | Key for that bucket (from `2-security` outputs) |

## Best practice

- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services) (as checked by Security Hub)
- [AWS Foundational Security Best Practices standard](https://docs.aws.amazon.com/securityhub/latest/userguide/fsbp-standard.html)
