# Account safety settings (`account-baseline`)

**What it builds:** the set-and-forget safety settings every Solution A
account gets, plus a history of every resource's settings (AWS Config),
sent to the central Security account.

**Used by:** Solution A (`3-shared-services` and each environment). The
Solution A demo switches it off, because it shares an account with
Solution B and the team's IAM users.

## What you get

| Setting | Why | Benchmark |
|---|---|---|
| Account-wide block on public buckets | No bucket in the account can ever be made public | CIS 2.1.4, AWS FSBP S3.1 |
| New disks always encrypted | Every new disk is encrypted automatically | CIS 2.2.1, AWS FSBP EC2.7 |
| Strong password rules | A backstop in case an IAM user is ever created | CIS 1.8, 1.9 |
| Configuration history (AWS Config) | A record of how every resource's settings change over time, kept in the Security account | CIS 3.3, AWS FSBP Config.1 |

## Settings

| Setting | Meaning |
|---|---|
| `name` | Name prefix |
| `config_bucket_name` | The central configuration-history bucket (from step 2, `2-security`) |
| `config_kms_key_arn` | The key for that bucket (from step 2) |

Further reading: [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services), [AWS Foundational Security Best Practices](https://docs.aws.amazon.com/securityhub/latest/userguide/fsbp-standard.html).
