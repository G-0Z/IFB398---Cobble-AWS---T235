# Application Load Balancer: the public front door. It spreads requests
# across healthy containers and (with a certificate) handles HTTPS.

#tfsec:ignore:aws-elb-alb-not-public -- by design: this is the internet-facing entry point for tenants.
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = var.load_balancer_subnet_ids

  # Rejects malformed HTTP headers, a common request-smuggling trick.
  drop_invalid_header_fields = true
  enable_deletion_protection = var.enable_deletion_protection

  dynamic "access_logs" {
    for_each = var.access_log_bucket_id != null ? [1] : []

    content {
      bucket  = var.access_log_bucket_id
      prefix  = "alb"
      enabled = true
    }
  }
}

resource "aws_lb_target_group" "this" {
  name        = "${var.name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # Fargate containers register by IP address

  health_check {
    path                = var.health_check_path
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }
}

# --- With a certificate: HTTPS, and HTTP redirects to HTTPS -----------------

resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  # Allows TLS 1.2 and 1.3 only (AWS's recommended policy).
  ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# --- Without a certificate (demo only): plain HTTP --------------------------

#tfsec:ignore:aws-elb-http-not-used -- only created when no certificate is supplied (Solution B's demo has no domain). Any environment with a certificate gets HTTPS and a redirect instead.
resource "aws_lb_listener" "http_forward" {
  count             = var.certificate_arn == null ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
