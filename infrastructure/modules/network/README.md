# `network` module

## Purpose

One VPC, with public and private subnets across however many AZs
`public_subnet_cidrs`/`private_subnet_cidrs` have entries for. Used by both
solutions. Solution B uses the defaults (no NAT, no database tier); Solution A
turns on the optional extras below.

## Files

| File | Contents |
|---|---|
| `main.tf` | VPC, subnets, internet gateway, route tables |
| `flow-logs.tf` | VPC Flow Logs, delivered through the `log-delivery` module |
| `nat.tf` | Optional NAT gateways and their routes (`nat_gateway_mode`) |
| `database-subnets.tf` | Optional database subnets with no internet route (`database_subnet_cidrs`) |
| `endpoints.tf` | Optional free S3 gateway endpoint (`enable_s3_gateway_endpoint`) |
| `default-security-group.tf` | Optionally strips all rules from the VPC's default security group (`restrict_default_security_group`) |

## Resources created

- `aws_vpc`, `aws_internet_gateway`
- `aws_subnet` × N public, × N private (paired by index with the AZ list)
- `aws_route_table` + associations — public routes `0.0.0.0/0` to the IGW;
  private has no internet route (no NAT gateway yet)
- `aws_flow_log`: captures ALL traffic for the VPC (Guide section 4.3),
  into an encrypted log group kept 30 days (`log-delivery` module).

## Inputs

| Name | Description |
|---|---|
| `project_name` | Naming prefix |
| `vpc_cidr` | VPC CIDR block |
| `public_subnet_cidrs` | List of public subnet CIDRs, one per AZ |
| `private_subnet_cidrs` | List of private subnet CIDRs, one per AZ |
| `kms_key_arn` | KMS key ARN to encrypt the flow log group with (from `security-baseline`'s `kms_key_arn` output) |
| `nat_gateway_mode` | `"none"` (default), `"single"` or `"one_per_az"` |
| `database_subnet_cidrs` | Database subnets, one per AZ (default: none) |
| `enable_s3_gateway_endpoint` | Add an S3 gateway endpoint (default: false) |
| `restrict_default_security_group` | Remove all rules from the default security group (default: false) |

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | VPC ID |
| `public_subnet_ids` | Public subnet IDs |
| `private_subnet_ids` | Private subnet IDs |
| `database_subnet_ids` | Database subnet IDs (empty by default) |
| `vpc_cidr` | The VPC's IP range |

## Known simplifications

- With the defaults (Solution B) there is no NAT gateway, so private subnets
  can't reach the internet. Solution A sets `nat_gateway_mode`.
- No security groups are defined here; each workload module
  (`container-service`, `postgres-database`) owns its own.

## Best practice

- One NAT gateway per AZ for production, so one AZ failing doesn't cut off
  the others: [NAT gateway basics](https://docs.aws.amazon.com/vpc/latest/userguide/nat-gateway-basics.html)
  (Well-Architected REL10).
- Separate subnet tiers so databases have no route to the internet:
  Well-Architected SEC05.
