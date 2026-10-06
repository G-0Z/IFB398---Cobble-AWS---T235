# Alerts: any new HIGH or CRITICAL Security Hub finding (which includes
# GuardDuty's threat findings) is emailed to security_alert_email. Lower
# severities are reviewed on the Security Hub dashboard instead, so the
# inbox isn't flooded.

resource "aws_sns_topic" "security_alerts" {
  name              = "cobble-security-alerts"
  kms_master_key_id = aws_kms_key.security.arn
}

resource "aws_sns_topic_policy" "security_alerts" {
  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "EventBridgePublishes"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.security_alerts.arn
      Condition = { StringEquals = { "aws:SourceAccount" = local.security_account_id } }
    }]
  })
}

# The recipient must click the confirmation link AWS emails them.
resource "aws_sns_topic_subscription" "security_alerts_email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.security_alert_email
}

resource "aws_cloudwatch_event_rule" "high_severity_findings" {
  name        = "cobble-high-severity-findings"
  description = "New HIGH or CRITICAL Security Hub findings"

  event_pattern = jsonencode({
    source        = ["aws.securityhub"]
    "detail-type" = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity    = { Label = ["HIGH", "CRITICAL"] }
        Workflow    = { Status = ["NEW"] }
        RecordState = ["ACTIVE"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "email_security_team" {
  rule = aws_cloudwatch_event_rule.high_severity_findings.name
  arn  = aws_sns_topic.security_alerts.arn
}
