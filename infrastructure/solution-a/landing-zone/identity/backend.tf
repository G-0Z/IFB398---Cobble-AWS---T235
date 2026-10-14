# Same state bucket as Solution B and the workload (infrastructure/bootstrap).
terraform {
  backend "s3" {
    bucket       = "cobble-tfstate-669591255093"
    key          = "solution-a/landing-zone/identity/terraform.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
    encrypt      = true
  }
}
