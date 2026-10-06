provider "aws" {
  region = var.aws_region

  # Refuses to plan or apply against any other account, so a teammate
  # signed in to the wrong account fails fast instead of deploying there.
  allowed_account_ids = [var.account_id]

  # Required tags from the Implementation Guide's naming standard. Plane and
  # Module are omitted: they describe application workloads, and this config
  # only deploys the landing zone.
  default_tags {
    tags = {
      Application = "Cobbled"
      Environment = "poc"
      ManagedBy   = "IaC"
      Owner       = var.owner
      CostCentre  = var.cost_centre
      DataClass   = var.data_class
      Criticality = var.criticality
    }
  }
}
