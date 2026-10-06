# Runbook: bootstrap the state bucket

**When:** once per AWS account, before anyone deploys. The PoC account
(`669591255093`) is already bootstrapped: skip this unless the state bucket
`cobble-tfstate-669591255093` is missing.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.10
- [AWS CLI](https://aws.amazon.com/cli/)
- Signed in to the AWS CLI as described in [deploy.md](deploy.md#sign-in),
  with rights to create S3 buckets. Never use root.

## Steps

```powershell
aws sts get-caller-identity   # Account must be 669591255093

cd infrastructure/bootstrap
terraform init
terraform apply
```

The provider refuses to run against any account other than `account_id`
in `variables.tf`, so a wrong-account apply fails before changing anything.

## Check

The `state_bucket_name` output must match the `bucket` in
`infrastructure/envs/poc/backend.tf`. If it doesn't, update `backend.tf`.

## Notes

Bootstrap keeps its state in a local `terraform.tfstate`, which is gitignored.
**Currently held by:** Max Gosling. If that file is lost, the bucket keeps
working; re-adopt it with:

```powershell
terraform import aws_s3_bucket.tfstate cobble-tfstate-669591255093
```

(and the same for the versioning, encryption and public-access-block
resources, using the bucket name as the ID). Moving this state into the
bucket itself is a deferred improvement, see
[ADR 0001](../docs/02-landing-zone-design/adr/0001-deferred-landing-zone-design.md).
