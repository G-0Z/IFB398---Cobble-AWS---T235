# Modules

The building blocks both solutions are made from. Each module builds one
thing well (a network, a database, a hardened bucket) and is used by the
folders in `solution-b/` and `solution-a/`. You never run Terraform in a
module directly, except to run its tests.

Every module has a README saying what it builds and why, and automated tests
that use a pretend AWS, so they need no AWS sign-in and cost nothing.

| Module | Builds | Used by |
|---|---|---|
| [`network`](network/) | A private network across two zones, with traffic logging. Optionally NAT gateways and a database layer | A, B |
| [`s3-bucket`](s3-bucket/) | One hardened S3 bucket: encrypted, versioned, never public | A, B |
| [`log-delivery`](log-delivery/) | One encrypted log group, plus the permission a service needs to write to it | A, B |
| [`container-service`](container-service/) | Web servers (containers on ECS Fargate) behind a load balancer, with auto scaling and an optional web firewall | A, B (optional demo) |
| [`github-oidc`](github-oidc/) | GitHub's access to AWS: a read-only role for checks and a deploy role that needs approval | A, B |
| [`security-baseline`](security-baseline/) | Solution B's account security: encryption key, audit trail, threat detection, access-log bucket | B |
| [`access-log-bucket`](access-log-bucket/) | The bucket that collects storage and load balancer access logs | A |
| [`account-baseline`](account-baseline/) | Account-wide safety settings and configuration history | A |
| [`postgres-database`](postgres-database/) | A private, encrypted PostgreSQL database | A |

`security-baseline` (B) and `access-log-bucket` (A) overlap a little on
purpose. Solution A keeps its audit logs in a separate Security account, so
it needed its own access-log bucket rather than B's all-in-one version.

**Adding to a module:** new optional features are `enable_<feature>`
switches that default to off, so adding something for Solution A never
changes what Solution B builds.

Run one module's tests:

```powershell
cd infrastructure/modules/<name>
terraform init
terraform test
```
