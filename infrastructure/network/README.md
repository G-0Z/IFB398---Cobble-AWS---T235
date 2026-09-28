## Purpose

PoC networking: one VPC, public and private subnets across however many AZs
`public_subnet_cidrs`/`private_subnet_cidrs` have entries for.

## Resources created

- `aws_vpc`, `aws_internet_gateway`
- `aws_subnet` × N public, × N private (paired by index with the AZ list)
- `aws_route_table` + associations — public routes `0.0.0.0/0` to the IGW;
  private has no internet route (no NAT gateway yet)
- `aws_flow_log` (+ CloudWatch Logs group, encrypted, and an IAM role scoped
  to just that log group) — captures ALL traffic for the VPC, per section
  4.3 of the engineering guide.

## Inputs

| Name | Description |
|---|---|
| `project_name` | Naming prefix |
| `vpc_cidr` | VPC CIDR block |
| `public_subnet_cidrs` | List of public subnet CIDRs, one per AZ |
| `private_subnet_cidrs` | List of private subnet CIDRs, one per AZ |
| `kms_key_arn` | KMS key ARN to encrypt the flow log group with (from `foundation/logging`'s `kms_key_arn` output) |

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | VPC ID |
| `public_subnet_ids` | Public subnet IDs |
| `private_subnet_ids` | Private subnet IDs |

## Known simplifications

- No NAT gateway: private subnets can't reach the internet yet. Fine for a
  PoC with no compute in those subnets; add a NAT gateway (or NAT instance,
  cheaper for a student budget) when something actually needs to run there.
- No security groups defined here — nothing is deployed into these subnets
  yet, so there's nothing to scope a security group to.
