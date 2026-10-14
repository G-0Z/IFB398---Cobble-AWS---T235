# One CloudTrail trail for the whole organisation: every API call, in every
# account and every region, lands in the locked audit log bucket. Member
# accounts can see it but can't stop or change it.

#tfsec:ignore:aws-cloudtrail-ensure-cloudwatch-integration -- alerting comes from GuardDuty and Security Hub (alerts.tf). Streaming the organisation trail into CloudWatch for CIS metric filters is a Phase 2 item.
resource "aws_cloudtrail" "organization" {
  provider = aws.management

  name                          = local.trail_name
  s3_bucket_name                = module.trail_bucket.bucket_name
  kms_key_id                    = aws_kms_key.security.arn
  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  depends_on = [module.trail_bucket]
}
