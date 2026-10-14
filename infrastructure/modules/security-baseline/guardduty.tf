# Off when the account's GuardDuty is managed elsewhere: once Solution A's
# landing zone runs in this account (1-organization), it owns the one
# detector AWS allows per region.
resource "aws_guardduty_detector" "this" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true
}
