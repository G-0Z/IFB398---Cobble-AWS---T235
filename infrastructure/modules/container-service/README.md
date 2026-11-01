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

## Good to know

- If a new release can't start healthy, the service rolls back to the previous version automatically.
- Further reading: [ECS security best practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security.html), [the two ECS roles](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html), [AWS WAF managed rules](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html), [load balancer TLS policies](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/describe-ssl-policies.html).

## Usage

How it's called in [`solution-a/workload/main.tf`](../../solution-a/workload/main.tf):

```hcl
module "app" {
  source = "../../modules/container-service"

  name                     = local.name
  vpc_id                   = module.network.vpc_id
  load_balancer_subnet_ids = module.network.public_subnet_ids
  task_subnet_ids          = module.network.private_subnet_ids

  container_image           = var.container_image
  container_port            = var.container_port
  cpu                       = var.app_cpu
  memory                    = var.app_memory
  desired_count             = var.app_desired_count
  max_count                 = var.app_max_count
  health_check_path         = var.health_check_path
  read_only_root_filesystem = var.read_only_root_filesystem

  # Connection details for the database and data bucket. The password is
  # read from Secrets Manager when the container starts; it is never stored
  # in the task definition. The app currently signs in as the database admin
  # user; a separate, least-privilege app user is a Phase 2 task.
  environment_variables = {
    DB_HOST     = module.database.endpoint
    DB_PORT     = tostring(module.database.port)
    DB_NAME     = module.database.database_name
    DATA_BUCKET = module.data_bucket.bucket_name
  }
  secrets = {
    DB_USERNAME = "${module.database.admin_secret_arn}:username::"
    DB_PASSWORD = "${module.database.admin_secret_arn}:password::"
  }
  secrets_kms_key_arn = aws_kms_key.this.arn

  # What the app itself may do in AWS: read and write its data bucket.
  task_role_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = module.data_bucket.bucket_arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${module.data_bucket.bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = aws_kms_key.this.arn
      },
    ]
  })

  certificate_arn            = var.certificate_arn
  enable_waf                 = var.enable_waf
  access_log_bucket_id       = module.access_logs.bucket_id
  enable_deletion_protection = var.protect_from_deletion
  kms_key_arn                = aws_kms_key.this.arn
  log_retention_days         = var.log_retention_days
  enable_container_insights  = var.enable_container_insights
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
| container\_image | Container image to run, e.g. "<account>.dkr.ecr.ap-southeast-2.amazonaws.com/cobble-module:1.4.0". Use a fixed version tag, not "latest". | `string` | n/a | yes |
| kms\_key\_arn | KMS key that encrypts the container log group. Its policy must allow the CloudWatch Logs service. | `string` | n/a | yes |
| load\_balancer\_subnet\_ids | Public subnets for the load balancer (at least two AZs). | `list(string)` | n/a | yes |
| name | Prefix for every resource name, e.g. "cobble-dev". | `string` | n/a | yes |
| task\_subnet\_ids | Subnets the containers run in. Private subnets with a NAT gateway in Solution A; public subnets in Solution B's demo (no NAT, to save cost). | `list(string)` | n/a | yes |
| vpc\_id | VPC the service runs in. | `string` | n/a | yes |
| access\_log\_bucket\_id | Bucket for load balancer access logs (must accept them; see access-log-bucket's allow\_load\_balancer\_logs). null turns them off. | `string` | `null` | no |
| assign\_public\_ip | Give each container a public IP. Only needed when task\_subnet\_ids are public subnets (Solution B's demo). The security group still only accepts traffic from the load balancer. | `bool` | `false` | no |
| certificate\_arn | ACM certificate for HTTPS. With a certificate: HTTPS on 443, and HTTP redirects to HTTPS. null (no domain yet): plain HTTP only, for demos. | `string` | `null` | no |
| container\_port | Port the container listens on. | `number` | `80` | no |
| cpu | CPU units per container (256 = 0.25 vCPU). | `number` | `256` | no |
| desired\_count | How many copies of the container to run. 2 or more for production, so one can fail without downtime. | `number` | `1` | no |
| enable\_container\_insights | Detailed CPU and memory metrics for the cluster (small extra cost). | `bool` | `false` | no |
| enable\_deletion\_protection | Stop the load balancer being deleted by accident. false for test environments so they tear down cleanly. | `bool` | `false` | no |
| enable\_waf | Put an AWS WAF web firewall in front of the load balancer (AWS managed rules plus a rate limit). | `bool` | `false` | no |
| environment\_variables | Plain (non-secret) settings passed to the container. | `map(string)` | `{}` | no |
| health\_check\_path | Path the load balancer requests to check a container is healthy. | `string` | `"/"` | no |
| log\_retention\_days | How long container logs are kept. | `number` | `30` | no |
| max\_count | Most containers auto scaling may run. null turns auto scaling off and keeps exactly desired\_count. When set, desired\_count is the minimum. | `number` | `null` | no |
| memory | Memory per container, in MiB. Must be a valid pairing with cpu (see AWS Fargate task sizes). | `number` | `512` | no |
| read\_only\_root\_filesystem | Stop the container writing to its own filesystem (best practice). Some images, such as the stock nginx demo, need to write and won't start with this on. | `bool` | `true` | no |
| secrets | Secret settings, as name => Secrets Manager reference (secret ARN, optionally followed by :json-key::). Read at start-up; never stored in the task definition. | `map(string)` | `{}` | no |
| secrets\_kms\_key\_arn | KMS key the secrets are encrypted with, so the containers can decrypt them. null if secrets use the AWS-managed key. | `string` | `null` | no |
| target\_cpu\_percent | Average CPU auto scaling aims for. The Implementation Guide suggests 55-65. | `number` | `60` | no |
| task\_role\_policy\_json | Optional IAM policy (JSON) for what the application itself may do in AWS, e.g. read its data bucket. null gives the app no AWS permissions. | `string` | `null` | no |
| waf\_rate\_limit | Maximum requests from one IP address in any 5-minute window before WAF blocks it. | `number` | `2000` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| cluster\_name | ECS cluster name. |
| load\_balancer\_dns\_name | Load balancer DNS name, for a Route 53 alias record. |
| load\_balancer\_zone\_id | Load balancer hosted zone ID, for a Route 53 alias record. |
| service\_name | ECS service name. |
| task\_security\_group\_id | The containers' security group, so a database can accept connections from them. |
| url | Address to open in a browser. |
| web\_acl\_arn | WAF web ACL ARN, or null when enable\_waf is false. |
<!-- END_TF_DOCS -->
