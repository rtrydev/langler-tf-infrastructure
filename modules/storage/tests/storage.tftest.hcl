mock_provider "aws" {}

run "plans_with_on_demand_capacity" {
  command = plan

  variables {
    table_name = "langler-prod"
  }

  assert {
    condition     = aws_dynamodb_table.application.billing_mode == "PAY_PER_REQUEST"
    error_message = "The table must use on-demand capacity."
  }

  assert {
    condition     = aws_dynamodb_table.application.hash_key == "PK" && aws_dynamodb_table.application.range_key == "SK"
    error_message = "The single-table key contract must remain PK/SK."
  }


  assert {
    condition     = aws_dynamodb_table.application.ttl[0].enabled && aws_dynamodb_table.application.ttl[0].attribute_name == "expiresAtUnix"
    error_message = "Ephemeral per-token rate-limit windows must expire through DynamoDB TTL."
  }
}
