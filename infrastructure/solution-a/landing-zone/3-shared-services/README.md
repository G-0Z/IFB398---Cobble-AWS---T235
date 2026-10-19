# Step 3: shared services

Things every environment uses, kept out of the environments themselves.
Today that's the container registry: the one place application images are
stored, so dev, staging and prod all run the same tested image.

| | |
|---|---|
| **Builds** | A private container registry (images can't be overwritten, are scanned when pushed, and can only be pulled from inside the organisation), the account's safety settings, and a budget |
| **Runs in** | The Shared Services account. After step 2, before the environments |
| **You fill in** | `settings.auto.tfvars` (copy the `.example`): account IDs from step 1 and outputs from step 2 |
| **Gives the next step** | `container_registry_url`, which goes into each environment's `container_image` |
| **Runbook** | [deploy-solution-a.md, step 3](../../../../runbooks/deploy-solution-a.md#step-3-shared-services-account) |
