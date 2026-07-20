output "alerts_topic_arn" {
  description = "SNS topic ARN carrying alarm and budget notifications"
  value       = aws_sns_topic.alerts.arn
}
