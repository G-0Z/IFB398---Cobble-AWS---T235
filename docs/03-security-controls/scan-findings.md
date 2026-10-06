# Security scan findings register

Every change is scanned by two tools. This register records what they found
in the Terraform code (both solutions) and what was decided about each
finding, so nothing is silently ignored.

| Tool | Where it runs | Result (6 Oct 2026) |
|---|---|---|
| [tfsec](https://github.com/aquasecurity/tfsec) | CI, every pull request | **0 open findings** on all 8 root configs. Each deliberate exception has an inline `#tfsec:ignore` comment giving the reason. |
| [Checkov](https://www.checkov.io/) | Run by hand as a stricter second opinion | **75 findings across 32 checks**, all reviewed below. 1 fixed; the rest are deliberate trade-offs, false positives, or Phase 2 work. |

**Why so many Checkov findings?** Checkov reads each module on its own,
without the values each environment passes in. So, for example, it flags
"load balancer uses HTTP" even though HTTPS switches on whenever a
certificate is supplied, and "no deletion protection" even though prod turns
it on.

## Fixed

| Check | Finding | Fix |
|---|---|---|
| CKV2_AWS_12 | VPC default security group allows traffic (CIS 5.4) | `restrict_default_security_group` added to `network`; on in every Solution A environment |

## Deliberate trade-offs

| Check(s) | Finding | Decision | Applies to |
|---|---|---|---|
| CKV_AWS_144, CKV2_AWS_62 | No cross-region replication; no S3 event notifications | Disaster recovery to a second region is out of scope (project plan). Notifications aren't needed. | Both |
| CKV_AWS_145, CKV_AWS_18 | Some buckets use SSE-S3, not KMS; some buckets don't log access | Access-log buckets can only use SSE-S3 and can't log to themselves (AWS limitation). The state bucket stays self-contained (ADR 0002). | Both |
| CKV_AWS_338 | CloudWatch log retention under 1 year | 30 to 90 days in CloudWatch keeps cost down; audit logs are kept long term in S3 (Object Lock in A) | Both |
| CKV_AWS_130, CKV_AWS_333 | Public subnets assign public IPs; demo container has a public IP | Public tier by design. Solution B's demo avoids a NAT gateway (~US$43/month); its firewall only accepts the load balancer. Solution A's containers are private. | B (demo) |
| CKV_AWS_260 | Port 80 open to the internet | The load balancer is the public entry point; with a certificate, port 80 only redirects to HTTPS | Both |
| CKV_AWS_274, CKV_AWS_109, CKV_AWS_110, CKV_AWS_111, CKV_AWS_107, CKV_AWS_108, CKV_AWS_356, CKV2_AWS_40 | Broad IAM permissions | Solution B's deploy role (`iam:*` and others) is a documented simplification (ADR 0001). Solution A's apply role is admin of its own account only, behind GitHub environment approval and SCPs (ADR 0003). The KMS key policies' `"Resource": "*"` is how KMS key policies work (it means the key itself). | Both |
| CKV_AWS_136 | ECR not encrypted with KMS | AWS-managed encryption keeps cross-account pulls simple; images hold code, not tenant data | A |
| CKV_AWS_121, CKV2_AWS_3 | Config and GuardDuty not in all regions | The restrict-regions SCP blocks every other region | A |
| CKV_AWS_394 | Availability zone data source not pinned | Zones are picked by index; a pinned list would break the module in other regions | Both |

## False positives (Checkov can't see the inputs)

| Check(s) | Finding | Why it doesn't apply |
|---|---|---|
| CKV_AWS_378, CKV_AWS_103, CKV2_AWS_20 | Load balancer uses HTTP / no TLS 1.2 / no redirect | HTTPS (TLS 1.2+) and a redirect switch on whenever `certificate_arn` is set. Plain HTTP only exists without a certificate (B's demo). |
| CKV_AWS_150, CKV_AWS_65, CKV_AWS_118 | No deletion protection, container insights or enhanced monitoring | Set per environment; deletion protection and container insights are on in prod |
| CKV2_AWS_76 | WAF missing Log4j rules | `AWSManagedRulesKnownBadInputsRuleSet`, which contains the Log4j rules, is included (`waf.tf`) |
| CKV_AWS_70 | Bucket policy allows any principal | Those statements are `Deny` (refuse non-HTTPS), or `Allow` limited by `aws:PrincipalOrgID` to the organisation |
| CKV2_AWS_61 | No lifecycle configuration | Lifecycle rules are optional inputs to `s3-bucket`; Solution A's log and data buckets set them |

## Phase 2

| Check | Finding | Plan |
|---|---|---|
| CKV2_AWS_10, CKV_AWS_252 | CloudTrail not streamed to CloudWatch / no SNS topic | Stream the organisation trail to CloudWatch and add CIS 4.x metric-filter alarms |
| CKV2_AWS_31 | WAF has no logging | Send WAF logs to a CloudWatch log group in each environment |

## How to re-run

```powershell
# tfsec (same as CI), from the repo root:
tfsec infrastructure/solution-a/4-workloads/prod

# Checkov:
pip install checkov
checkov -d infrastructure --framework terraform
```
