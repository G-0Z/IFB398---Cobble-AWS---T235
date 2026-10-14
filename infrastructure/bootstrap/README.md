# Bootstrap: the state bucket

Terraform keeps a record of everything it builds, called its **state**. This
folder creates the S3 bucket where every other folder keeps that record, so
the whole team shares one up-to-date copy.

| | |
|---|---|
| **Builds** | One S3 bucket: versioned, encrypted, never public, protected from deletion |
| **Run it** | Once per AWS account, by hand, before anything else. The team's account already has it (`cobble-tfstate-669591255093`) |
| **Runbook** | [runbooks/bootstrap.md](../../runbooks/bootstrap.md) |

## Why it's separate

Terraform can't create the bucket it stores its own records in during the
same run that uses it. So this small folder keeps its own record locally (in
a git-ignored `terraform.tfstate` file here) and only ever creates the
bucket.

The bucket also handles locking, so two people can't change the same thing
at once (Terraform 1.10 or later).

## For Solution A

[`org-access.tf`](org-access.tf) adds a bucket policy that lets the GitHub
roles in Solution A's environment accounts reach their own records under
`solution-a/workload/`. It's only created when `organization_id` is set, so
Solution B's bucket isn't affected.

## Things to know

- Running it again changes nothing, so it's safe to re-run.
- Never delete the bucket while any folder still keeps its records in it.
- The bucket name is written into every other folder's `backend.tf` (Terraform doesn't allow a variable there). If it ever changes, update them all: the list is in [runbooks/README.md](../../runbooks/README.md#deploying-into-a-different-aws-account).
- The local `terraform.tfstate` is the only copy of this folder's record. Keep a backup somewhere outside the repo, and never move or rename this folder: Git would move the code and leave the record behind.
