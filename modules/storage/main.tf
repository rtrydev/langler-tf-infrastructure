resource "aws_dynamodb_table" "application" {
  #checkov:skip=CKV_AWS_28:Point-in-time recovery is billable and task data remains reproducible during the foundation phase
  #checkov:skip=CKV_AWS_119:AWS-owned DynamoDB encryption avoids KMS request costs for this low-risk personal application
  name           = var.table_name
  billing_mode   = "PROVISIONED"
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  hash_key       = "PK"
  range_key      = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = false
  }
}
