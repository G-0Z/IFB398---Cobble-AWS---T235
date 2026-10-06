# Firewall rules (security groups). Traffic can only flow:
#   internet -> load balancer -> containers
# The containers accept nothing except from the load balancer.

resource "aws_security_group" "load_balancer" {
  name        = "${var.name}-alb"
  description = "Load balancer: accepts web traffic from the internet"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_security_group" "tasks" {
  name        = "${var.name}-tasks"
  description = "Containers: accept traffic only from the load balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-tasks"
  }
}

#tfsec:ignore:aws-ec2-no-public-ingress-sgr -- the load balancer is the public front door; WAF (when on) filters this traffic.
resource "aws_vpc_security_group_ingress_rule" "load_balancer_http" {
  security_group_id = aws_security_group.load_balancer.id
  description       = "HTTP from the internet (redirected to HTTPS when a certificate is set)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

#tfsec:ignore:aws-ec2-no-public-ingress-sgr -- the load balancer is the public front door; WAF (when on) filters this traffic.
resource "aws_vpc_security_group_ingress_rule" "load_balancer_https" {
  count             = var.certificate_arn != null ? 1 : 0
  security_group_id = aws_security_group.load_balancer.id
  description       = "HTTPS from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "load_balancer_to_tasks" {
  security_group_id            = aws_security_group.load_balancer.id
  description                  = "Forward requests to the containers"
  referenced_security_group_id = aws_security_group.tasks.id
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
}

resource "aws_vpc_security_group_ingress_rule" "tasks_from_load_balancer" {
  security_group_id            = aws_security_group.tasks.id
  description                  = "Requests from the load balancer only"
  referenced_security_group_id = aws_security_group.load_balancer.id
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr -- containers must reach AWS APIs and pull images over HTTPS. Outbound only; nothing can connect in.
resource "aws_vpc_security_group_egress_rule" "tasks_https_out" {
  security_group_id = aws_security_group.tasks.id
  description       = "HTTPS out: image pulls, AWS APIs, Secrets Manager"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
