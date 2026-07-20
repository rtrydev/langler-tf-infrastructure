mock_provider "aws" {}

variables {
  name                     = "langler-prod"
  alarm_email              = "owner@example.com"
  table_name               = "langler-prod"
  api_function_name        = "langler-prod-api"
  authorizer_function_name = "langler-prod-machine-authorizer"
  http_api_id              = "abc123"
  machine_api_id           = "def456"
}

run "plans_lambda_and_api_gateway_alarms" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.api_lambda_errors.dimensions["FunctionName"] == var.api_function_name
    error_message = "The api Lambda error alarm must target the api function."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.authorizer_lambda_errors.dimensions["FunctionName"] == var.authorizer_function_name
    error_message = "The authorizer error alarm must target the authorizer function."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.human_api_5xx.dimensions["ApiId"] == var.http_api_id && aws_cloudwatch_metric_alarm.machine_api_5xx.dimensions["ApiId"] == var.machine_api_id
    error_message = "The 5xx alarms must target their respective HTTP APIs."
  }

  assert {
    condition = alltrue([
      for alarm in [
        aws_cloudwatch_metric_alarm.api_lambda_errors,
        aws_cloudwatch_metric_alarm.api_lambda_throttles,
        aws_cloudwatch_metric_alarm.authorizer_lambda_errors,
        aws_cloudwatch_metric_alarm.authorizer_lambda_throttles,
        aws_cloudwatch_metric_alarm.human_api_5xx,
        aws_cloudwatch_metric_alarm.machine_api_5xx,
        aws_cloudwatch_metric_alarm.dynamodb_read_throttled,
        aws_cloudwatch_metric_alarm.dynamodb_write_throttled,
      ] : length(alarm.alarm_actions) == 1 && length(alarm.ok_actions) == 1
    ])
    error_message = "Every alarm must notify exactly one action (the shared alerts SNS topic)."
  }

  assert {
    condition     = alltrue([for alarm in [aws_cloudwatch_metric_alarm.api_lambda_errors, aws_cloudwatch_metric_alarm.dynamodb_read_throttled] : alarm.treat_missing_data == "notBreaching"])
    error_message = "No traffic must not itself be treated as an alarm condition for a near-zero-idle-cost app."
  }
}

run "plans_dynamodb_capacity_alarms_with_default_threshold" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.dynamodb_consumed_read_capacity.threshold == 1000 && aws_cloudwatch_metric_alarm.dynamodb_consumed_write_capacity.threshold == 1000
    error_message = "Consumed-capacity alarms must default to the documented 1000-unit threshold."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.dynamodb_consumed_read_capacity.dimensions["TableName"] == var.table_name
    error_message = "Consumed-capacity alarms must target the application table."
  }
}

run "plans_monthly_budget_with_percentage_notifications" {
  command = plan

  assert {
    condition     = aws_budgets_budget.monthly.limit_amount == "10" && aws_budgets_budget.monthly.limit_unit == "USD"
    error_message = "The default monthly budget must be $10."
  }

  assert {
    condition = anytrue([
      for n in aws_budgets_budget.monthly.notification : n.threshold == 85 && n.notification_type == "ACTUAL" && contains(n.subscriber_email_addresses, var.alarm_email)
    ])
    error_message = "The budget must notify the owner email at 85% actual spend."
  }

  assert {
    condition = anytrue([
      for n in aws_budgets_budget.monthly.notification : n.threshold == 100 && n.notification_type == "FORECASTED"
    ])
    error_message = "The budget must also notify on 100% forecasted spend."
  }
}

run "rejects_non_positive_budget" {
  command = plan

  variables {
    monthly_budget_usd = "0"
  }

  expect_failures = [var.monthly_budget_usd]
}

run "rejects_invalid_email" {
  command = plan

  variables {
    alarm_email = "not-an-email"
  }

  expect_failures = [var.alarm_email]
}
