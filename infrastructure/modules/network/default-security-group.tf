# Every VPC comes with a "default" security group that allows traffic
# between its members. Nothing here should use it, so with
# restrict_default_security_group = true Terraform takes over that group
# and removes all its rules (CIS AWS Foundations Benchmark 5.4).
# Solution B leaves this off, so its VPC is unchanged.

resource "aws_default_security_group" "this" {
  count  = var.restrict_default_security_group ? 1 : 0
  vpc_id = aws_vpc.this.id

  # No ingress or egress blocks: no traffic allowed.

  tags = {
    Name = "${var.project_name}-default-do-not-use"
  }
}
