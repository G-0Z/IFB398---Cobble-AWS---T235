# Security scan findings register

Two tools scan the code for security mistakes. This page records everything
they found and what we decided about each finding, so nothing is quietly
ignored.

**In short:** the scanner that guards every change (Trivy) reports nothing
open. The stricter second opinion (Checkov) reports 75 findings. We fixed
one, and the rest are deliberate trade-offs, false alarms, or Phase 2 work,
each explained below. A manual review found five more issues that no
scanner could see, and all five are fixed.

| Tool | Where it runs | Result (6 Oct 2026) |
|---|---|---|
| [Trivy](https://trivy.dev/) | Automatically on every pull request, on all 7 root configs. A finding blocks the merge | **0 open findings** (14 Oct 2026, Trivy 0.74.0). Each deliberate exception is a comment next to the code, giving the reason |
| [Checkov](https://www.checkov.io/) | By hand, as a stricter second opinion | **75 findings across 32 checks**, all reviewed below |

**Why so many Checkov findings?** Checkov reads each building block on its
own, without the settings each environment gives it. So it flags "load
balancer uses HTTP" even though HTTPS switches on as soon as there's a
certificate, and "no deletion protection" even though prod turns it on.

## Fixed

| Check | Finding | Fix |
|---|---|---|
| CKV2_AWS_12 | VPC default security group allows traffic (CIS 5.4) | `restrict_default_security_group` added to `network`; on in every Solution A environment |

## Deliberate trade-offs

| Check(s) | Finding | Decision | Applies to |
|---|---|---|---|
| CKV_AWS_144, CKV2_AWS_62 | No cross-region replication; no S3 event notifications | Disaster recovery to a second region is out of scope (project plan). Notifications aren't needed. | Both |
| CKV_AWS_145, CKV_AWS_18 | Some buckets use SSE-S3, not KMS; some buckets don't log access | Access-log buckets can only use SSE-S3 and can't log to themselves (AWS limitation). The state bucket stays self-contained. | Both |
| CKV_AWS_338 | CloudWatch log retention under 1 year | 30 to 90 days in CloudWatch keeps cost down; audit logs are kept long term in S3 (Object Lock in A) | Both |
| CKV_AWS_130, CKV_AWS_333 | Public subnets assign public IPs; demo container has a public IP | Public tier by design. Solution B's demo avoids a NAT gateway (~A$62/month); its firewall only accepts the load balancer. Solution A's containers are private. | B (demo) |
| CKV_AWS_260 | Port 80 open to the internet | The load balancer is the public entry point; with a certificate, port 80 only redirects to HTTPS | Both |
| CKV_AWS_274, CKV_AWS_109, CKV_AWS_110, CKV_AWS_111, CKV_AWS_107, CKV_AWS_108, CKV_AWS_356, CKV2_AWS_40 | Broad IAM permissions | The GitHub deploy role is admin of its own account only, and can only be used after a reviewer approves the deployment; in Solution A, guardrails also limit it. The KMS key policies' `"Resource": "*"` is how KMS key policies work (it means the key itself). | Both |
| CKV_AWS_136 | ECR not encrypted with KMS | AWS-managed encryption keeps cross-account pulls simple; images hold code, not tenant data | A |
| CKV_AWS_121, CKV2_AWS_3 | Config and GuardDuty not in all regions | The restrict-regions SCP blocks every other region | A |
| CKV_AWS_394 | Availability zone data source not pinned | Zones are picked by index; a pinned list would break the module in other regions | Both |

## False alarms (Checkov can't see the settings)

| Check(s) | Finding | Why it doesn't apply |
|---|---|---|
| CKV_AWS_378, CKV_AWS_103, CKV2_AWS_20 | Load balancer uses HTTP / no TLS 1.2 / no redirect | HTTPS (TLS 1.2+) and a redirect switch on whenever `certificate_arn` is set. Plain HTTP only exists without a certificate (B's demo). |
| CKV_AWS_150, CKV_AWS_65, CKV_AWS_118 | No deletion protection, container insights or enhanced monitoring | Set per environment; deletion protection and container insights are on in prod |
| CKV2_AWS_76 | WAF missing Log4j rules | `AWSManagedRulesKnownBadInputsRuleSet`, which contains the Log4j rules, is included (`waf.tf`) |
| CKV_AWS_70 | Bucket policy allows any principal | Those statements are `Deny` (refuse non-HTTPS), or `Allow` limited by `aws:PrincipalOrgID` to the organisation |
| CKV2_AWS_61 | No lifecycle configuration | Lifecycle rules are optional inputs to `s3-bucket`; Solution A's log and data buckets set them |

## Found by manual review (7 Oct 2026)

Issues no scanner reports, because they depend on how the pieces fit together. All are fixed.

| Finding | Fix |
|---|---|
| The security-services SCP blocked turning services *off*, but not quietly disabling them: emptying the Config recorder, auto-archiving GuardDuty findings, suppressing Security Hub findings, deleting flow logs | 11 more actions denied in `1-organization/policies/protect-security-services.json.tftpl` |
| GitHub's read-only role could read the contents of buckets and logs. Anyone with a branch can open a pull request, so tenant data was reachable | `plan_no_data` policy in `modules/github-oidc/main.tf` denies it, except the state file; tested |
| The automatic checks only covered Solution B: Solution A's code and most module tests never ran | Every root config and module added to `.github/workflows/ci.yml` |
| CI's GitHub token had the repo's default permissions; actions were pinned by movable tags | `permissions: contents: read`; every action pinned to a commit hash |
| Solution A's filled-in settings files (real account IDs and emails) weren't git-ignored | Added to `.gitignore` |

## Phase 2

| Check | Finding | Plan |
|---|---|---|
| CKV2_AWS_10, CKV_AWS_252 | CloudTrail not streamed to CloudWatch / no SNS topic | Stream the organisation trail to CloudWatch and add CIS 4.x metric-filter alarms |
| CKV2_AWS_31 | WAF has no logging | Send WAF logs to a CloudWatch log group in each environment |

## How to re-run

```powershell
# Trivy (same as CI), from the repo root:
trivy config --ignorefile .trivyignore.yaml infrastructure/solution-a/workload

# Checkov:
pip install checkov
checkov -d infrastructure --framework terraform
```
