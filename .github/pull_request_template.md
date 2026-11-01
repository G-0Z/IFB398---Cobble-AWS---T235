## What and why

<!-- One or two sentences. Link the issue: Closes #… -->

## How it was checked

- [ ] `terraform fmt -recursive` (in `infrastructure/`) and `terraform validate` in each root config touched
- [ ] `terraform test` in each module touched
- [ ] `terraform-docs -c ../.terraform-docs.yml .` in each module whose variables or outputs changed
- [ ] For changes that deploy: deployed, torn down and redeployed; a final `terraform plan -detailed-exitcode` exits 0; run recorded in the evidence log (`docs/deliverables/evidence.md`)
- [ ] Output, numbers or screenshots attached for anything visible or measured

## Definition of done

- [ ] CI is green (reviewers: check before approving)
- [ ] Reviewed by one other team member
- [ ] Docs, runbooks and the control map (`infrastructure/README.md`) updated if behaviour or commands changed
- [ ] No backend `key` changed; no `settings.auto.tfvars`, `users.csv`, `*.tfplan` or `*.tfstate` committed
- [ ] Screenshots redacted: account IDs, organisation IDs, emails and ARNs
