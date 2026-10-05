# Runbook: bootstrap the state bucket

**When:** once per AWS account, before anyone deploys. If the bucket already
exists, skip this.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.10
- [AWS CLI](https://aws.amazon.com/cli/)
- An IAM user access key (never root) with rights to create S3 buckets

## Steps

```powershell
aws configure                 # IAM access key, region ap-southeast-2
aws sts get-caller-identity   # confirms credentials are live

cd infrastructure/bootstrap
terraform init
terraform apply
```

## Check

The `state_bucket_name` output must match the `bucket` in
`infrastructure/envs/poc/backend.tf`. If it doesn't, update `backend.tf`.

## Notes

The local `terraform.tfstate` this creates is gitignored. Keep it: it's the
only record of the state bucket.
