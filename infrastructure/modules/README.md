# modules/{plane}/{code}/

Reserved for future Cobbled *application module* infrastructure — the
per-module ECR repo, API service, route, alarms, secrets and widget
artifact for each independently deployable Application Plane / Admin
Plane / Application User Module (e.g. `adm/mod`, `aum/mms`). See the
Cobbled AWS Platform Engineering Implementation Guide, section 15.1.

Not to be confused with the reusable Terraform building blocks in
`foundation/`, `network/` and `data/` — those are platform infrastructure,
this is per-Cobbled-module infrastructure. Empty for now: this PoC does
not deploy any Cobbled application modules yet.
