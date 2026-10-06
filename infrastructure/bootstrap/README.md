# `bootstrap`: Terraform state bucket

Creates the S3 bucket that `infrastructure/envs/poc/backend.tf` stores its
state in. It's a separate root config with its own local state, applied
once per AWS account, by hand.

## Why it's separate

Terraform can't create the bucket it stores its own state in during the same
apply that uses it as a backend. So this tiny config keeps its state locally
(a gitignored `.tfstate` in this folder) and only ever creates one thing.

State locking uses the bucket itself (`use_lockfile`, Terraform >= 1.10), so
no DynamoDB table is needed.

## Setup

See [`runbooks/bootstrap.md`](../../runbooks/bootstrap.md).

## Resources created

- `aws_s3_bucket`: versioned, SSE-S3 encrypted, all public access blocked,
  no `force_destroy`.

## Notes

- Applying again is a no-op, so it's safe to re-run.
- Don't delete the bucket while anyone still has state in it.
- The bucket name is hardcoded in `envs/poc/backend.tf`, because backend
  blocks can't reference variables. Keep the two in sync.
