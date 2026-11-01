# Runbook: create the state bucket

**What it does:** creates the S3 bucket where Terraform keeps its records
for every other folder.

**When:** once per AWS account, before anything else is deployed. The
team's account (`669591255093`) already has it, so skip this unless the
bucket `cobble-tfstate-669591255093` is missing.

## Before you start

- Terraform 1.10 or later, and the AWS CLI
- Signed in to the team's account ([deploy-solution-b.md](deploy-solution-b.md#sign-in)) with rights to create S3 buckets. Never use the root user

## Steps

```powershell
aws sts get-caller-identity   # Account must be 669591255093

cd infrastructure/bootstrap
terraform init
terraform apply
```

Terraform refuses to run against any account other than the one in
`variables.tf`, so a mistake fails before it changes anything.

## Check

The `state_bucket_name` output must match the bucket name in every
`backend.tf` (see [runbooks/README.md](README.md#deploying-into-a-different-aws-account)).

## If the local record is lost

This folder keeps its own record in a local `terraform.tfstate` file, which
isn't on GitHub. **Currently held by:** Max Gosling.

If that file is lost, the bucket keeps working. To bring it back under
Terraform, import it:

```powershell
terraform import aws_s3_bucket.tfstate cobble-tfstate-669591255093
```

Then do the same for its versioning, encryption and public-access-block
settings, using the bucket name as the ID.
