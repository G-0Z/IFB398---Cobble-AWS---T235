# Container service (`container-service`)

**What it builds:** web servers running as containers on ECS Fargate, behind
a load balancer, with auto scaling and an optional web firewall in front.
There are no servers for us to patch: AWS runs them.

**Used by:** Solution A (every environment) and Solution B's optional demo
web page (`enable_demo_app`).

## How traffic flows

```
Internet → [web firewall, optional] → load balancer (public subnets)
         → web servers (private subnets in Solution A) → database / storage
```

The web servers only accept traffic from the load balancer.

## What's in each file

| File | Holds |
|---|---|
| `security-groups.tf` | Firewall rules: internet → load balancer → web servers |
| `load-balancer.tf` | The load balancer, its health checks, and HTTPS (or plain HTTP for demos with no certificate) |
| `waf.tf` | The web firewall: AWS managed rules plus a per-IP rate limit (`enable_waf`) |
| `iam.tf` | Two roles: one lets AWS start the container, the other says what the app itself may do |
| `ecs.tf` | The cluster, the encrypted log group, the container definition and the service that keeps it running |
| `autoscaling.tf` | Adds web servers when CPU is busy, up to `max_count` (off by default) |

## Main settings

| Setting | Meaning | Default |
|---|---|---|
| `container_image` | The image to run. Use a fixed version, never `latest` | required |
| `cpu`, `memory` | Size of each web server | 256 (¼ vCPU), 512 MiB |
| `desired_count` | How many run (the minimum when auto scaling is on) | 1 |
| `max_count` | Auto scaling ceiling. `null` means no auto scaling | `null` |
| `certificate_arn` | HTTPS certificate. `null` means plain HTTP, for demos only | `null` |
| `enable_waf` | Web firewall | `false` |
| `secrets` | Secret settings, read from Secrets Manager when the server starts | none |
| `task_role_policy_json` | What the app may do in AWS | nothing |
| `assign_public_ip` | Only for Solution B's demo, where servers sit in public subnets | `false` |

The full list, with descriptions, is in `variables.tf`.

**Outputs:** `url`, `load_balancer_dns_name`, `load_balancer_zone_id`, `task_security_group_id`, `cluster_name`, `service_name`, `web_acl_arn`

## Good to know

- If a new release can't start healthy, the service rolls back to the previous version automatically.
- Further reading: [ECS security best practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security.html), [the two ECS roles](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html), [AWS WAF managed rules](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html), [load balancer TLS policies](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/describe-ssl-policies.html).
