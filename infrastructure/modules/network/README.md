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

## Main settings

| Setting | Meaning | Default |
|---|---|---|
| `project_name` | Name prefix | required |
| `vpc_cidr` | The network's IP range | required |
| `public_subnet_cidrs`, `private_subnet_cidrs` | One IP range per zone | required |
| `kms_key_arn` | Key that encrypts the traffic logs | required |
| `nat_gateway_mode` | `none`, `single` or `one_per_az` | `none` |
| `database_subnet_cidrs` | One IP range per zone for the database section | none |
| `enable_s3_gateway_endpoint` | Add the free S3 path | `false` |
| `restrict_default_security_group` | Lock the default firewall rule | `false` |

**Outputs:** `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `database_subnet_ids`, `vpc_cidr`

## Good to know

- With the defaults (Solution B) there's no NAT gateway, which saves about A$62 a month. The trade-off is that private subnets can't reach the internet.
- Firewall rules (security groups) aren't defined here. Each module that runs something (`container-service`, `postgres-database`) owns its own.
- AWS recommends one NAT gateway per zone in production, so losing one zone doesn't cut the others off ([NAT gateway basics](https://docs.aws.amazon.com/vpc/latest/userguide/nat-gateway-basics.html); Well-Architected REL10). Separate subnet layers keep databases off the internet (Well-Architected SEC05).
