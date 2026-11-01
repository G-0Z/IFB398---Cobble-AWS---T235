# Network (`network`)

**What it builds:** a private network (VPC) across two availability zones,
divided into public and private sections, with all traffic logged.

**Used by:** both solutions. Solution B uses the basics. Solution A switches
on the extras: NAT gateways, a database section and a locked-down default
firewall rule.

## What you get

| Part | Why |
|---|---|
| VPC and internet gateway | The network itself, and its door to the internet |
| Public subnets, one per zone | For things that must face the internet: the load balancer and NAT gateways |
| Private subnets, one per zone | For the web servers. Nothing on the internet can reach them directly |
| Traffic logs (VPC Flow Logs) | Every connection, allowed or refused, is recorded in an encrypted log (Guide §4.3) |
| *Optional:* NAT gateways | Let private servers reach out to the internet without being reachable. One shared (`single`) or one per zone (`one_per_az`, for prod) |
| *Optional:* database subnets | A third section with no route to the internet at all |
| *Optional:* S3 gateway endpoint | Free private path to S3 that skips the NAT gateway |
| *Optional:* locked default firewall rule | Removes all rules from the network's default security group (CIS 5.4) |

## Good to know

- With the defaults (Solution B) there's no NAT gateway, which saves about A$62 a month. The trade-off is that private subnets can't reach the internet.
- Firewall rules (security groups) aren't defined here. Each module that runs something (`container-service`, `postgres-database`) owns its own.
- AWS recommends one NAT gateway per zone in production, so losing one zone doesn't cut the others off ([NAT gateway basics](https://docs.aws.amazon.com/vpc/latest/userguide/nat-gateway-basics.html); Well-Architected REL10). Separate subnet layers keep databases off the internet (Well-Architected SEC05).

## Usage

How it's called in [`solution-a/workload/main.tf`](../../solution-a/workload/main.tf):

```hcl
module "network" {
  source = "../../modules/network"

  project_name                    = local.name
  vpc_cidr                        = var.vpc_cidr
  public_subnet_cidrs             = var.public_subnet_cidrs
  private_subnet_cidrs            = var.private_subnet_cidrs
  database_subnet_cidrs           = var.database_subnet_cidrs
  nat_gateway_mode                = var.nat_gateway_mode
  enable_s3_gateway_endpoint      = true
  restrict_default_security_group = true
  kms_key_arn                     = aws_kms_key.this.arn
}
```

## Reference

Generated from the module's code by [terraform-docs](https://terraform-docs.io/), so it's always
complete. Don't edit it by hand: run `terraform-docs -c ../.terraform-docs.yml .`
in this folder after changing a variable or output.

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.10 |
| aws | ~> 5.0 |

### Providers

| Name | Version |
| ---- | ------- |
| aws | ~> 5.0 |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| kms\_key\_arn | KMS key that encrypts the flow log group (security-baseline's kms\_key\_arn). Its policy must allow the CloudWatch Logs service. | `string` | n/a | yes |
| private\_subnet\_cidrs | CIDR blocks for private subnets, one per AZ used. | `list(string)` | n/a | yes |
| project\_name | Naming prefix. | `string` | n/a | yes |
| public\_subnet\_cidrs | CIDR blocks for public subnets, one per AZ used. | `list(string)` | n/a | yes |
| vpc\_cidr | CIDR block for the VPC. | `string` | n/a | yes |
| database\_subnet\_cidrs | One IP range per database subnet, one per AZ. These subnets never get an internet route. Leave empty for no database tier. | `list(string)` | `[]` | no |
| enable\_s3\_gateway\_endpoint | Add a free S3 gateway endpoint, so private and database subnets reach S3 without going through a NAT gateway. | `bool` | `false` | no |
| nat\_gateway\_mode | How private subnets reach the internet (outbound only):   "none"       - no internet access at all (cheapest; Solution B)   "single"     - one NAT gateway shared by every AZ (dev and staging)   "one\_per\_az" - one NAT gateway per AZ, so losing an AZ doesn't cut off                  the others (production; AWS Well-Architected REL10) | `string` | `"none"` | no |
| restrict\_default\_security\_group | Remove every rule from the VPC's default security group, so anything accidentally placed in it can't send or receive traffic (CIS 5.4). | `bool` | `false` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| database\_subnet\_ids | Database subnet IDs (empty if database\_subnet\_cidrs is empty). |
| private\_subnet\_ids | Private subnet IDs. |
| public\_subnet\_ids | Public subnet IDs. |
| vpc\_cidr | The VPC's IP range, for security group rules. |
| vpc\_id | VPC ID. |
<!-- END_TF_DOCS -->
