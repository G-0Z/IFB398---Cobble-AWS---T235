# Same state bucket as Solution B and the landing zone (infrastructure/bootstrap).
# Each environment has its own state file, chosen at init:
#   terraform init -reconfigure -backend-config="key=solution-a/workload/<environment>/terraform.tfstate"
terraform {
  backend "s3" {
    bucket       = "cobble-tfstate-669591255093"
    region       = "ap-southeast-2"
    use_lockfile = true
    encrypt      = true
  }
}
