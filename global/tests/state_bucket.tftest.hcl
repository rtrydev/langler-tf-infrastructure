mock_provider "aws" {}

run "plans_with_defaults" {
  command = plan

  assert {
    condition     = aws_s3_bucket.terraform_state.bucket == var.state_bucket_name
    error_message = "State bucket name must come from var.state_bucket_name"
  }

  assert {
    condition     = aws_s3_bucket_versioning.terraform_state.versioning_configuration[0].status == "Enabled"
    error_message = "State bucket versioning must be enabled so state history is recoverable"
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.terraform_state.rule).apply_server_side_encryption_by_default).sse_algorithm == "AES256"
    error_message = "State bucket must enforce server-side encryption"
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.terraform_state.block_public_acls,
      aws_s3_bucket_public_access_block.terraform_state.block_public_policy,
      aws_s3_bucket_public_access_block.terraform_state.ignore_public_acls,
      aws_s3_bucket_public_access_block.terraform_state.restrict_public_buckets,
    ])
    error_message = "State bucket must block all forms of public access"
  }
}

run "rejects_invalid_bucket_name" {
  command = plan

  variables {
    state_bucket_name = "Invalid_Bucket_Name"
  }

  expect_failures = [
    var.state_bucket_name,
  ]
}

run "rejects_adjacent_dots_in_bucket_name" {
  command = plan

  variables {
    state_bucket_name = "langler..terraform-state"
  }

  expect_failures = [
    var.state_bucket_name,
  ]
}

run "rejects_ip_address_bucket_name" {
  command = plan

  variables {
    state_bucket_name = "192.168.0.1"
  }

  expect_failures = [
    var.state_bucket_name,
  ]
}

run "rejects_invalid_region" {
  command = plan

  variables {
    aws_region = "not-a-region"
  }

  expect_failures = [
    var.aws_region,
  ]
}
