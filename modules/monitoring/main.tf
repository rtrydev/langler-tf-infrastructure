resource "aws_cloudwatch_metric_alarm" "api_lambda_errors" {
  alarm_name          = "${var.name}-api-lambda-errors"
  alarm_description   = "The api Lambda returned at least one error in a 5-minute window."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = var.api_function_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "api_lambda_throttles" {
  alarm_name          = "${var.name}-api-lambda-throttles"
  alarm_description   = "The api Lambda was throttled in a 5-minute window."
  namespace           = "AWS/Lambda"
  metric_name         = "Throttles"
  dimensions          = { FunctionName = var.api_function_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "authorizer_lambda_errors" {
  alarm_name          = "${var.name}-authorizer-lambda-errors"
  alarm_description   = "The machine-token authorizer Lambda returned at least one error in a 5-minute window."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = var.authorizer_function_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "authorizer_lambda_throttles" {
  alarm_name          = "${var.name}-authorizer-lambda-throttles"
  alarm_description   = "The machine-token authorizer Lambda was throttled in a 5-minute window."
  namespace           = "AWS/Lambda"
  metric_name         = "Throttles"
  dimensions          = { FunctionName = var.authorizer_function_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "human_api_5xx" {
  alarm_name          = "${var.name}-human-api-5xx"
  alarm_description   = "The browser API returned at least one 5xx response in a 5-minute window."
  namespace           = "AWS/ApiGateway"
  metric_name         = "5xx"
  dimensions          = { ApiId = var.http_api_id, Stage = var.stage_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "machine_api_5xx" {
  alarm_name          = "${var.name}-machine-api-5xx"
  alarm_description   = "The machine-token API returned at least one 5xx response in a 5-minute window."
  namespace           = "AWS/ApiGateway"
  metric_name         = "5xx"
  dimensions          = { ApiId = var.machine_api_id, Stage = var.stage_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttled" {
  alarm_name          = "${var.name}-dynamodb-read-throttled"
  alarm_description   = "DynamoDB rejected at least one read request in a 5-minute window."
  namespace           = "AWS/DynamoDB"
  metric_name         = "ReadThrottleEvents"
  dimensions          = { TableName = var.table_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttled" {
  alarm_name          = "${var.name}-dynamodb-write-throttled"
  alarm_description   = "DynamoDB rejected at least one write request in a 5-minute window."
  namespace           = "AWS/DynamoDB"
  metric_name         = "WriteThrottleEvents"
  dimensions          = { TableName = var.table_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_consumed_read_capacity" {
  alarm_name          = "${var.name}-dynamodb-consumed-read-capacity"
  alarm_description   = "DynamoDB consumed read capacity spiked well above ordinary personal-app traffic."
  namespace           = "AWS/DynamoDB"
  metric_name         = "ConsumedReadCapacityUnits"
  dimensions          = { TableName = var.table_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.dynamodb_consumed_capacity_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_consumed_write_capacity" {
  alarm_name          = "${var.name}-dynamodb-consumed-write-capacity"
  alarm_description   = "DynamoDB consumed write capacity spiked well above ordinary personal-app traffic."
  namespace           = "AWS/DynamoDB"
  metric_name         = "ConsumedWriteCapacityUnits"
  dimensions          = { TableName = var.table_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.dynamodb_consumed_capacity_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_budgets_budget" "monthly" {
  name         = "${var.name}-monthly-cost"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
}
