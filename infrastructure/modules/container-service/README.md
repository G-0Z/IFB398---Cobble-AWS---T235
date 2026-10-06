# `container-service` module

**In one sentence:** runs a Cobble module as containers on ECS Fargate,
behind a load balancer, with an optional WAF web firewall in front.

**Used by:** Solution A (every environment) and Solution B's optional demo
app (`enable_demo_app`).

## How traffic flows

```
Internet -> [WAF, optional] -> Load balancer (public subnets)
         -> Containers (private subnets in Solution A) -> database / S3
```

The containers only accept traffic from the load balancer's security group.

## Files

| File | Contents |
|---|---|
| `security-groups.tf` | Firewall rules: internet -> load balancer -> containers |
| `load-balancer.tf` | Load balancer, health checks, HTTPS (or HTTP for demos) |
| `waf.tf` | AWS WAF with AWS managed rules and a per-IP rate limit (`enable_waf`) |
| `iam.tf` | Execution role (start the container) and task role (what the app may do) |
| `ecs.tf` | Cluster, encrypted log group, task definition, service |

## Inputs (main ones)

| Name | Meaning | Default |
|---|---|---|
| `container_image` | Image to run (use a fixed version tag) | required |
| `cpu`, `memory` | Size per container | 256, 512 |
| `desired_count` | Copies running | 1 |
| `certificate_arn` | HTTPS certificate; null = plain HTTP (demo only) | null |
| `enable_waf` | Web firewall | false |
| `secrets` | Secret settings read from Secrets Manager at start-up | {} |
| `task_role_policy_json` | What the app may do in AWS | null (nothing) |
| `assign_public_ip` | Only for public task subnets (Solution B demo) | false |

See `variables.tf` for every input with a description.

## Outputs

`url`, `load_balancer_dns_name`, `load_balancer_zone_id`, `task_security_group_id`, `cluster_name`, `service_name`, `web_acl_arn`

## Best practice

- [Amazon ECS security best practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security.html)
- [Task execution role vs task role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html)
- [AWS WAF managed rule groups](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html)
- [ALB security policies (TLS 1.2/1.3)](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/describe-ssl-policies.html)
