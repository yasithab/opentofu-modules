output "detector_arn" {
  description = "ARN of the GuardDuty detector"
  value       = try(aws_guardduty_detector.this.arn, "")
}

output "detector_id" {
  description = "ID of the GuardDuty detector"
  value       = try(aws_guardduty_detector.this.id, "")
}

output "detector_account_id" {
  description = "AWS account ID of the GuardDuty detector"
  value       = try(aws_guardduty_detector.this.account_id, "")
}

output "publishing_destination_id" {
  description = "ID of the GuardDuty publishing destination"
  value       = try(aws_guardduty_publishing_destination.this["this"].id, "")
}

output "ipset_ids" {
  description = "Map of IPSet names to their IDs"
  value       = { for k, v in aws_guardduty_ipset.this : k => v.id }
}

output "ipset_arns" {
  description = "Map of IPSet names to their ARNs"
  value       = { for k, v in aws_guardduty_ipset.this : k => v.arn }
}

output "threatintelset_ids" {
  description = "Map of ThreatIntelSet names to their IDs"
  value       = { for k, v in aws_guardduty_threatintelset.this : k => v.id }
}

output "threatintelset_arns" {
  description = "Map of ThreatIntelSet names to their ARNs"
  value       = { for k, v in aws_guardduty_threatintelset.this : k => v.arn }
}

output "filter_ids" {
  description = "Map of filter names to their IDs"
  value       = { for k, v in aws_guardduty_filter.this : k => v.id }
}

output "filter_arns" {
  description = "Map of filter names to their ARNs"
  value       = { for k, v in aws_guardduty_filter.this : k => v.arn }
}

output "member_account_ids" {
  description = "Map of member account friendly names to their account IDs"
  value       = { for k, v in aws_guardduty_member.this : k => v.account_id }
}
