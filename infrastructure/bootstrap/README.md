# Bootstrap: Terraform state backend

Creates the S3 bucket + DynamoDB lock table that `infrastructure/backend.tf`
points at. This has to exist *before* `terraform init` works in the main
`infrastructure/` config, so it's a separate root module with its own local
state, applied once, by hand.

## Why this is separate

Terraform can't create the S3 bucket it's about to store its own state in in
the same `terraform apply` that uses that bucket as a backend — chicken and
egg. So this tiny config uses local state (a `.tfstate` file in this folder,
gitignored) and only ever creates two things: the state bucket and the lock
table. Nobody should need to touch it again after the first apply.

## Setup

1. `aws configure` with your own IAM user's access key (never root).
2. `terraform init`
3. `terraform apply`
4. Confirm the bucket name matches `backend.tf` in `infrastructure/` (it's
   hardcoded there as `cobble-tfstate-669591255093`, since backend blocks
   can't reference variables).

After this, everyone else just runs `terraform init` in `infrastructure/`
and gets the same remote state.

## Resources created

- `aws_s3_bucket` — versioned, encrypted (SSE-S3), all public access blocked.
- `aws_dynamodb_table` — state lock table, pay-per-request, `LockID` hash key.

## Notes

- Only needs to be applied once per AWS account. If it already exists,
  running `apply` again is a no-op (still safe).
- Do not delete the bucket or table while anyone still has state in it.
