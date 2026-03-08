output "slack_configuration_arn" {
  description = "Amazon Resource Name (ARN) of the Slack channel configuration"
  value       = try(aws_chatbot_slack_channel_configuration.this.chat_configuration_arn, null)
}

output "slack_configuration_id" {
  description = "ID of the Slack channel configuration (ARN)"
  value       = try(aws_chatbot_slack_channel_configuration.this.chat_configuration_arn, null)
}

output "teams_configuration_arn" {
  description = "Amazon Resource Name (ARN) of the Teams channel configuration"
  value       = try(aws_chatbot_teams_channel_configuration.this.chat_configuration_arn, null)
}

output "teams_configuration_id" {
  description = "ID of the Teams channel configuration (ARN)"
  value       = try(aws_chatbot_teams_channel_configuration.this.chat_configuration_arn, null)
}

output "chatbot_role_arn" {
  description = "ARN of the IAM role used by AWS Chatbot"
  value       = try(aws_iam_role.chatbot.arn, null)
}

output "chatbot_role_name" {
  description = "Name of the IAM role used by AWS Chatbot"
  value       = try(aws_iam_role.chatbot.name, null)
}
