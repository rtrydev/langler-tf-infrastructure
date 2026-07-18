mock_provider "aws" {}

run "plans_with_free_tier_capacity" {
  command = plan

  variables {
    table_name = "langler-prod"
  }

  assert {
    condition     = aws_dynamodb_table.application.billing_mode == "PROVISIONED"
    error_message = "The table must use provisioned capacity to qualify for Always Free."
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

run "rejects_capacity_above_free_tier" {
  command = plan

  variables {
    table_name    = "langler-prod"
    read_capacity = 26
  }

  expect_failures = [var.read_capacity]
}
